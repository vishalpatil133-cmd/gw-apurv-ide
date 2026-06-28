import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import 'package:provider/provider.dart';
import '../providers/ide_provider.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal terminal;
  static const _methodChannel = MethodChannel('com.example.antigravity_ide/terminal_method');
  static const _eventChannel = EventChannel('com.example.antigravity_ide/terminal_event');

  StreamSubscription? _eventSubscription;
  bool _isExtracting = false;
  bool _isSessionActive = false;
  String _status = "Initializing...";

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Force portrait mode for terminal screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize xterm terminal instance
    terminal = Terminal(
      maxLines: 10000,
    );
    terminal.onOutput = _onTerminalInput;

    // Bootstrap check and launch session
    _setupAndStartSession();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    // Restore landscape mode upon exiting terminal screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _onTerminalInput(String input) {
    if (_isSessionActive) {
      _methodChannel.invokeMethod('write', {'data': input});
    }
  }

  Future<void> _setupAndStartSession() async {
    setState(() {
      _isExtracting = true;
      _status = "Checking bootstrap environment...";
    });

    try {
      // 1. Check/extract bootstrap zip environment
      final bool extractSuccess = await _methodChannel.invokeMethod('extractBootstrap');
      if (!extractSuccess) {
        setState(() {
          _isExtracting = false;
          _status = "Bootstrap extraction failed.";
        });
        terminal.write("Error: Failed to extract Termux bootstrap from assets.\r\n");
        terminal.write("Please place 'bootstrap-aarch64.zip' inside assets/ folder.\r\n");
        return;
      }

      setState(() {
        _isExtracting = false;
        _status = "Launching terminal session...";
      });

      // 2. Spawn native PTY subprocess
      // Run bash inside extracted Prefix, fallback to /system/bin/sh if missing
      final String prefixPath = "/data/data/com.example.antigravity_ide/files/usr";
      final bool sessionSuccess = await _methodChannel.invokeMethod('createSession', {
        'command': "$prefixPath/bin/bash",
        'arguments': ['--login'],
      });

      if (sessionSuccess) {
        setState(() {
          _isSessionActive = true;
          _status = "Session Active";
        });

        // 3. Set the layout window size in PTY
        _methodChannel.invokeMethod('resize', {
          'rows': terminal.viewHeight > 0 ? terminal.viewHeight : 24,
          'cols': terminal.viewWidth > 0 ? terminal.viewWidth : 80,
        });

        // Trigger any pending run command from Editor
        final provider = Provider.of<IdeProvider>(context, listen: false);
        if (provider.pendingTerminalCommand != null) {
          final cmd = provider.pendingTerminalCommand!;
          provider.pendingTerminalCommand = null;
          Future.delayed(const Duration(milliseconds: 1200), () {
            _methodChannel.invokeMethod('write', {'data': cmd});
          });
        }

        // 4. Stream stdout/stderr stream from Native PTY to Dart xterm
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen((data) {
          if (data is Uint8List) {
            terminal.write(String.fromCharCodes(data));
          }
        }, onError: (error) {
          terminal.write("\r\n[Stream Error: $error]\r\n");
        }, onDone: () {
          setState(() {
            _isSessionActive = false;
            _status = "Session Terminated";
          });
          terminal.write("\r\n[Process completed]\r\n");
        });
      } else {
        setState(() {
          _status = "Failed to launch shell subprocess.";
        });
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _status = "Init Error: $e";
      });
      terminal.write("\r\nError initializing terminal session: $e\r\n");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: Text(
          "TERMUX TERMINAL CONSOLE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.greenAccent[400],
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 10,
                  color: _isSessionActive ? Colors.green : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: () {
              _eventSubscription?.cancel();
              _setupAndStartSession();
            },
            tooltip: "Restart Session",
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isExtracting)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF1E1E1E),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            Expanded(
              child: Container(
                color: const Color(0xFF121212),
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Automatically resize the active pseudo-terminal on layout changes
                    final cols = (constraints.maxWidth / 7.2).floor();
                    final rows = (constraints.maxHeight / 14.0).floor();
                    if (_isSessionActive) {
                      _methodChannel.invokeMethod('resize', {
                        'rows': rows,
                        'cols': cols,
                      });
                    }
                    return TerminalView(
                      terminal,
                      autofocus: true,
                      textStyle: const TerminalStyle(
                        fontSize: 12,
                        fontFamily: "monospace",
                      ),
                    );
                  },
                ),
              ),
            ),
            // Virtual Shortcut Key Row (like Termux)
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShortcutButton("TAB", () => _onTerminalInput("\t")),
                    _buildShortcutButton("CTRL+C", () => _onTerminalInput("\x03")),
                    _buildShortcutButton("ESC", () => _onTerminalInput("\x1b")),
                    _buildShortcutButton("↑", () => _onTerminalInput("\x1b[A")),
                    _buildShortcutButton("↓", () => _onTerminalInput("\x1b[B")),
                    _buildShortcutButton("←", () => _onTerminalInput("\x1b[D")),
                    _buildShortcutButton("→", () => _onTerminalInput("\x1b[C")),
                    _buildShortcutButton("PWD", () => _onTerminalInput("pwd\n")),
                    _buildShortcutButton("LS", () => _onTerminalInput("ls\n")),
                    _buildShortcutButton("CLEAR", () => _onTerminalInput("clear\n")),
                  ],
                ),
              ),
            ),
            // Soft Keyboard Input TextField
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 4 : 8,
                left: 12,
                right: 12,
                top: 4,
              ),
              color: const Color(0xFF181818),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: "Type command...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (val) {
                        if (val.isNotEmpty) {
                          _onTerminalInput(val + "\n");
                          _inputController.clear();
                        }
                        _inputFocusNode.requestFocus();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.greenAccent, size: 18),
                    onPressed: () {
                      final val = _inputController.text;
                      if (val.isNotEmpty) {
                        _onTerminalInput(val + "\n");
                        _inputController.clear();
                      }
                      _inputFocusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(String label, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
