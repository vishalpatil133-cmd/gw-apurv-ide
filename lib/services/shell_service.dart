import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../providers/ide_provider.dart';

class ShellService {
  io.Process? _process;
  io.Socket? _socket;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;
  late Terminal _terminal;
  late IdeProvider _provider;

  // Virtual terminal state for Web / Fallback
  String _virtualCwd = "/workspace";
  String _inputBuffer = "";

  void initialize(Terminal terminal, IdeProvider provider) {
    _terminal = terminal;
    _provider = provider;

    if (kIsWeb) {
      _startVirtualShell();
    } else {
      _startRealShell();
    }
  }

  void writeToStdin(String input) {
    if (_socket != null) {
      _socket!.write(input);
    } else if (_process != null) {
      _process!.stdin.write(input);
    } else {
      _executeVirtualCommand(input.trim());
    }
  }

  void _startRealShell() async {
    try {
      final workingDir = _provider.workspaceDir?.path;
      // On Android, attempt to trigger and connect to Termux Bridge
      if (!io.Platform.isWindows) {
        _terminal.write("\r\n[Shell] Initializing Termux environment bridge...\r\n");
        const termuxChannel = MethodChannel("com.example.antigravity_ide/termux_service");
        
        try {
          final bool bridgeStarted = await termuxChannel.invokeMethod("startTermuxBridge");
          if (bridgeStarted) {
            _terminal.write("  ↳ Termux service command triggered. Awaiting port binding...\r\n");
            
            // Try connecting to port 9090 on localhost (up to 3 attempts with delay)
            io.Socket? socketConnection;
            for (int i = 0; i < 3; i++) {
              await Future.delayed(const Duration(milliseconds: 600));
              try {
                socketConnection = await io.Socket.connect('127.0.0.1', 9090).timeout(const Duration(milliseconds: 1000));
                break;
              } catch (_) {}
            }

            if (socketConnection != null) {
              _socket = socketConnection;
              _terminal.write("\x1B[1;32m[Shell] Termux environment connected successfully! Natively running in Termux.\x1B[0m\r\n\r\n");
              
              if (workingDir != null && workingDir.isNotEmpty) {
                _socket!.write("cd \"$workingDir\"\n");
              }
              
              _socket!.listen(
                (data) {
                  _terminal.write(utf8.decode(data, allowMalformed: true).replaceAll('\n', '\r\n'));
                },
                onError: (e) {
                  _terminal.write("\r\n[Shell] Termux connection error: $e. Falling back to local sh.\r\n");
                  _socket = null;
                  _startLocalSystemShell();
                },
                onDone: () {
                  _terminal.write("\r\n[Shell] Termux connection closed. Falling back to local sh.\r\n");
                  _socket = null;
                  _startLocalSystemShell();
                }
              );

              _terminal.onOutput = (data) {
                _socket?.write(data);
              };
              return; // Successfully initialized Termux bridge
            } else {
              _terminal.write("  ↳ Connection timed out (Termux may be stopped or 'Allow external applications' disabled in termux.properties).\r\n");
            }
          } else {
            _terminal.write("  ↳ Failed to trigger Termux RunCommandService intent.\r\n");
          }
        } catch (e) {
          _terminal.write("  ↳ Termux link skipped: $e\r\n");
        }
      }

      _startLocalSystemShell();
    } catch (e) {
      _terminal.write("\r\n[Shell] Native shell error: $e. Starting virtual shell.\r\n");
      _startVirtualShell();
    }
  }

  void _startLocalSystemShell() async {
    try {
      final workingDir = _provider.workspaceDir?.path;
      final shell = io.Platform.isWindows ? 'cmd.exe' : 'sh';

      _terminal.write("[Shell] Spawning local system shell ($shell)...\r\n");
      
      _process = await io.Process.start(
        shell,
        [],
        workingDirectory: workingDir,
      );

      _stdoutSub = _process!.stdout.transform(utf8.decoder).listen((data) {
        _terminal.write(data.replaceAll('\n', '\r\n'));
      });

      _stderrSub = _process!.stderr.transform(utf8.decoder).listen((data) {
        _terminal.write(data.replaceAll('\n', '\r\n'));
      });

      _terminal.onOutput = (data) {
        _process!.stdin.write(data);
      };

      if (!io.Platform.isWindows) {
        _process!.stdin.write("command -v gcc >/dev/null 2>&1 || echo '\x1B[1;31m[WARNING] GCC compiler not detected! Install build-essential package to compile C.\x1B[0m'\n");
        _process!.stdin.write("command -v python3 >/dev/null 2>&1 || echo '\x1B[1;31m[WARNING] Python3 interpreter not detected! Install Python 3 to run python offline.\x1B[0m'\n");
      }

      _process!.exitCode.then((code) {
        _terminal.write("\r\n[Shell] Process exited with code $code. Falling back to virtual shell.\r\n");
        _startVirtualShell();
      });
    } catch (e) {
      _terminal.write("\r\n[Shell] Local system shell error: $e. Starting virtual shell.\r\n");
      _startVirtualShell();
    }
  }

  void _startVirtualShell() {
    _terminal.write("\r\n[Virtual Shell] Welcome to GW-IDE Terminal Console.\r\nType 'help' for available commands.\r\n\r\n");
    _showVirtualPrompt();

    _terminal.onOutput = (data) {
      for (int i = 0; i < data.length; i++) {
        final char = data[i];
        if (char == '\r' || char == '\n') {
          _terminal.write("\r\n");
          _executeVirtualCommand(_inputBuffer.trim());
          _inputBuffer = "";
          _showVirtualPrompt();
        } else if (char == '\x7f' || char == '\b') {
          if (_inputBuffer.isNotEmpty) {
            _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
            _terminal.write("\b \b");
          }
        } else {
          _inputBuffer += char;
          _terminal.write(char);
        }
      }
    };
  }

  void _showVirtualPrompt() {
    _terminal.write("\x1B[1;32mgwide@web\x1B[0m:\x1B[1;34m$_virtualCwd\x1B[0m\$ ");
  }

  void _executeVirtualCommand(String commandLine) {
    if (commandLine.isEmpty) return;

    final parts = commandLine.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.sublist(1);

    switch (cmd) {
      case 'help':
        _terminal.write("Available virtual commands:\r\n"
            "  ls, dir          List workspace files\r\n"
            "  cd <dir>         Change virtual directory\r\n"
            "  pwd              Print working directory\r\n"
            "  cat <file>       Print file contents\r\n"
            "  echo <text>      Print text to terminal\r\n"
            "  clear            Clear terminal screen\r\n"
            "  flutter run      Simulate running the Flutter app\r\n"
            "  flutter build    Run 'flutter build apk' release tool\r\n"
            "  help             Show this help information\r\n");
        break;
      case 'clear':
        _terminal.write('\x1b[2J\x1b[H');
        break;
      case 'pwd':
        _terminal.write("$_virtualCwd\r\n");
        break;
      case 'echo':
        _terminal.write("${args.join(' ')}\r\n");
        break;
      case 'ls':
      case 'dir':
        final files = _provider.files;
        if (files.isEmpty) {
          _terminal.write("Directory is empty or no workspace loaded.\r\n");
        } else {
          for (final f in files) {
            final isDir = f is io.Directory;
            final name = f.path.split(io.Platform.isWindows ? '\\' : '/').last;
            if (isDir) {
              _terminal.write("\x1B[1;34m$name/\x1B[0m\r\n");
            } else {
              _terminal.write("$name\r\n");
            }
          }
        }
        break;
      case 'cd':
        if (args.isEmpty) {
          _virtualCwd = "/workspace";
        } else {
          final target = args[0];
          if (target == "..") {
            if (_virtualCwd != "/workspace") {
              final lastSlash = _virtualCwd.lastIndexOf('/');
              _virtualCwd = lastSlash > 0 ? _virtualCwd.substring(0, lastSlash) : "/workspace";
            }
          } else {
            _virtualCwd = "$_virtualCwd/$target".replaceAll('//', '/');
          }
        }
        break;
      case 'cat':
        if (args.isEmpty) {
          _terminal.write("Usage: cat <filename>\r\n");
        } else {
          final filename = args[0];
          final fileEntity = _provider.files.firstWhere(
            (f) => f.path.endsWith(filename),
            orElse: () => throw Exception("File not found"),
          );
          if (fileEntity is io.File) {
            final content = fileEntity.readAsStringSync();
            _terminal.write(content.replaceAll('\n', '\r\n') + "\r\n");
          } else {
            _terminal.write("cat: $filename: Is a directory or cannot read\r\n");
          }
        }
        break;
      case 'flutter':
        if (args.isEmpty) {
          _terminal.write("Flutter SDK Virtual CLI\r\nUse 'flutter run' or 'flutter build'\r\n");
        } else if (args[0] == 'run') {
          _terminal.write("Launching application on Chrome/Android (Simulated)...\r\n");
          _terminal.write("Syncing files to device...\r\n");
          _terminal.write("\x1B[1;32mRunning! URL: http://localhost:8080/\x1B[0m\r\n");
        } else if (args[0] == 'build' && args.length > 1 && args[1] == 'apk') {
          _terminal.write("Starting Flutter Release APK build...\r\n");
          _provider.buildApk();
        } else {
          _terminal.write("Unknown flutter command: ${args.join(' ')}\r\n");
        }
        break;
      default:
        _terminal.write("gwide-sh: command not found: $cmd. Type 'help' for support.\r\n");
    }
  }

  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
  }
}
