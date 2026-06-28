import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:bonsoir/bonsoir.dart';

class P2PCollaborationService {
  HttpServer? _server;
  WebSocket? _clientSocket;
  final List<WebSocket> _hostSockets = [];
  bool _isHosting = false;
  bool _isConnected = false;
  int _latency = 0;
  Timer? _pingTimer;

  // mDNS Discovery State
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  bool get isHosting => _isHosting;
  bool get isConnected => _isConnected || _hostSockets.isNotEmpty;
  int get latency => _latency;

  // Callbacks
  Function(String log)? onLog;
  Function(String filePath, String content)? onFileUpdated;
  Function(String filePath)? onActiveTabChanged;
  Function(String text)? onEditorUpdated;
  Function(String command)? onTerminalExecuted;
  Function(Map<String, dynamic> files)? onInitReceived;
  Function(int latency)? onLatencyUpdated;
  Function(String status)? onStatusChanged;
  Function(double dx, double dy)? onMouseMove;
  Function()? onMouseClick;
  Function()? onMouseDoubleClick;
  Function()? onMouseLongPress;
  Function(String text)? onKeyboardInput;
  Function(bool ctrl, bool shift, bool alt)? onModifierChanged;

  /// Fowler–Noll–Vo FNV-1a 32-bit hash checksum calculation (offline-compatible)
  static int calculateChecksum(List<int> bytes) {
    int hash = 2166136261;
    for (int b in bytes) {
      hash ^= b;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Retrieves local non-loopback IPv4 addresses
  static Future<List<String>> getLocalIps() async {
    List<String> ips = [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          ips.add(addr.address);
        }
      }
    } catch (e) {
      // ignore
    }
    if (ips.isEmpty) {
      ips.add("127.0.0.1");
    }
    return ips;
  }

  /// Start P2P hosting server on Phone A (Supports SecurityContext for WSS)
  Future<int> startHosting(String ip, Directory workspaceDir, {SecurityContext? securityContext}) async {
    await stopAll();
    _isHosting = true;
    if (onStatusChanged != null) onStatusChanged!("Hosting");
    
    if (securityContext != null) {
      _server = await HttpServer.bindSecure(ip, 0, securityContext);
      _log("Secure P2P WSS Server bound successfully.");
    } else {
      _server = await HttpServer.bind(ip, 0);
      _log("Standard P2P WS Server bound successfully.");
    }
    
    int port = _server!.port;

    _server!.listen((HttpRequest request) async {
      if (request.uri.path == '/ws') {
        try {
          var socket = await WebSocketTransformer.upgrade(request);
          _hostSockets.add(socket);
          _log("Collaborator connected via P2P socket!");
          onStatusChanged?.call("Connected");
          
          await _sendInitialSnapshot(socket, workspaceDir);

          socket.listen((message) {
            _handleIncomingMessage(message);
          }, onDone: () {
            _hostSockets.remove(socket);
            _log("Collaborator disconnected.");
            onStatusChanged?.call("Hosting");
          });
        } catch (e) {
          _log("Error upgrading WebSocket: $e");
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write("GW IDE P2P Host Active")
          ..close();
      }
    });

    _log("P2P server running at port $port");
    _startHeartbeat();
    
    // Broadcast service via mDNS (bonsoir)
    try {
      await startMdnsBroadcast("GW_IDE_Host_${port}", port);
    } catch (e) {
      _log("Failed to start mDNS broadcast: $e");
    }
    
    return port;
  }

  /// Join P2P session on Phone B
  Future<void> joinSession(String code, Directory workspaceDir) async {
    await stopAll();
    String target = code.trim();
    if (!target.contains("://")) {
      target = "ws://$target";
    }
    if (!target.endsWith("/ws")) {
      target = "$target/ws";
    }

    _log("Connecting to host P2P session: $target...");
    if (onStatusChanged != null) onStatusChanged!("Connecting");
    
    try {
      _clientSocket = await WebSocket.connect(target).timeout(const Duration(seconds: 8));
      _isConnected = true;
      if (onStatusChanged != null) onStatusChanged!("Connected");
      _log("Connected to project host successfully!");

      _clientSocket!.listen((message) {
        _handleIncomingMessage(message);
      }, onDone: () {
        _isConnected = false;
        if (onStatusChanged != null) onStatusChanged!("Reconnecting");
        _log("Disconnected from P2P session.");
      }, onError: (e) {
        _isConnected = false;
        if (onStatusChanged != null) onStatusChanged!("Disconnected");
        _log("P2P connection error: $e");
      });

      _startHeartbeat();
    } catch (e) {
      if (onStatusChanged != null) onStatusChanged!("Disconnected");
      rethrow;
    }
  }

  /// Stop all active P2P connections and servers
  Future<void> stopAll() async {
    stopMdns();
    _pingTimer?.cancel();
    _isHosting = false;
    _isConnected = false;
    _latency = 0;
    
    for (var socket in _hostSockets) {
      await socket.close();
    }
    _hostSockets.clear();

    if (_clientSocket != null) {
      await _clientSocket!.close();
      _clientSocket = null;
    }

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    if (onStatusChanged != null) onStatusChanged!("Disconnected");
    _log("All P2P connections stopped.");
  }

  /// Start mDNS bonsoir broadcast
  Future<void> startMdnsBroadcast(String name, int port) async {
    _broadcast?.stop();
    BonsoirService service = BonsoirService(
      name: name,
      type: '_gwide-p2p._tcp',
      port: port,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
    _log("mDNS bonsoir broadcast active on port $port");
  }

  /// Start mDNS discovery to automatically resolve peers
  Future<void> startMdnsDiscovery(Function(String pairingCode) onPeerResolved) async {
    _discovery?.stop();
    _discovery = BonsoirDiscovery(type: '_gwide-p2p._tcp');
    await _discovery!.initialize();
    _discovery!.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent && event.service != null) {
        event.service!.resolve(_discovery!.serviceResolver);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent && event.service != null) {
        final service = event.service!;
        final host = service.hostAddress;
        final port = service.port;
        _log("mDNS resolved peer: $host:$port");
        if (host != null) {
          onPeerResolved("$host:$port");
        }
      }
    });
    await _discovery!.start();
  }

  /// Stop all mDNS activities
  void stopMdns() {
    _broadcast?.stop();
    _broadcast = null;
    _discovery?.stop();
    _discovery = null;
  }

  /// Send updates to peers (broadcasts to all sockets)
  void sendData(Map<String, dynamic> packet) {
    final serialized = json.encode(packet);
    if (_isHosting) {
      for (var socket in _hostSockets) {
        socket.add(serialized);
      }
    } else if (_isConnected && _clientSocket != null) {
      _clientSocket!.add(serialized);
    }
  }

  /// Ping-Pong heartbeat initializer
  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isConnected) {
        sendData({
          "type": "ping",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  /// Sends initial snapshot of files including recursive checksum checks for assets
  Future<void> _sendInitialSnapshot(WebSocket socket, Directory dir) async {
    _log("Sending project snapshot to guest...");
    Map<String, String> filesMap = {};
    Map<String, String> assetsChecksumMap = {};

    try {
      final list = await dir.list(recursive: true).toList();
      for (var entity in list) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: dir.path);
          if (relativePath.startsWith("assets")) {
            // Calculate FNV-1a checksum for assets
            final bytes = await entity.readAsBytes();
            final sum = calculateChecksum(bytes);
            assetsChecksumMap[relativePath] = sum.toString();
          } else if (relativePath.endsWith(".dart") ||
              relativePath.endsWith(".py") ||
              relativePath.endsWith(".c") ||
              relativePath.endsWith(".cpp") ||
              relativePath.endsWith(".yaml")) {
            final content = await entity.readAsString();
            filesMap[relativePath] = content;
          }
        }
      }
      socket.add(json.encode({
        "type": "init",
        "files": filesMap,
        "assetsChecksums": assetsChecksumMap,
      }));
      _log("Project snapshot sent containing ${filesMap.length} code files and ${assetsChecksumMap.length} asset entries.");
    } catch (e) {
      _log("Failed to create snapshot: $e");
    }
  }

  /// Request transfer of specific modified asset blocks
  Future<void> requestAssetFile(String assetPath) async {
    sendData({
      "type": "asset_request",
      "path": assetPath,
    });
  }

  /// Handle incoming packet protocol
  void _handleIncomingMessage(dynamic rawMsg) {
    try {
      final data = json.decode(rawMsg as String) as Map<String, dynamic>;
      final type = data["type"] as String;

      switch (type) {
        case "ping":
          sendData({
            "type": "pong",
            "timestamp": data["timestamp"],
          });
          break;
        case "pong":
          final sentTime = data["timestamp"] as int;
          final now = DateTime.now().millisecondsSinceEpoch;
          _latency = now - sentTime;
          if (onLatencyUpdated != null) {
            onLatencyUpdated!(_latency);
          }
          break;
        case "init":
          if (onInitReceived != null) {
            onInitReceived!(data["files"] as Map<String, dynamic>);
          }
          // Process asset checksum comparison
          if (data["assetsChecksums"] != null) {
            final remoteChecksums = data["assetsChecksums"] as Map<String, dynamic>;
            remoteChecksums.forEach((path, sum) {
              requestAssetFile(path);
            });
          }
          break;
        case "file_update":
          if (onFileUpdated != null) {
            onFileUpdated!(data["filePath"] as String, data["content"] as String);
          }
          break;
        case "tab_change":
          if (onActiveTabChanged != null) {
            onActiveTabChanged!(data["filePath"] as String);
          }
          break;
        case "editor_update":
          if (onEditorUpdated != null) {
            onEditorUpdated!(data["text"] as String);
          }
          break;
        case "terminal_execute":
          if (onTerminalExecuted != null) {
            onTerminalExecuted!(data["command"] as String);
          }
          break;
        case "asset_request":
          _sendAssetFile(data["path"] as String);
          break;
        case "asset_payload":
          _receiveAssetFile(data["path"] as String, data["bytes"] as String);
          break;
        case "mouse_move":
          if (onMouseMove != null) {
            onMouseMove!(data["dx"] as double, data["dy"] as double);
          }
          break;
        case "mouse_click":
          if (onMouseClick != null) {
            onMouseClick!();
          }
          break;
        case "mouse_double_click":
          if (onMouseDoubleClick != null) {
            onMouseDoubleClick!();
          }
          break;
        case "mouse_long_press":
          if (onMouseLongPress != null) {
            onMouseLongPress!();
          }
          break;
        case "keyboard_input":
          if (onKeyboardInput != null) {
            onKeyboardInput!(data["text"] as String);
          }
          break;
        case "modifier_change":
          if (onModifierChanged != null) {
            onModifierChanged!(
              data["ctrl"] as bool? ?? false,
              data["shift"] as bool? ?? false,
              data["alt"] as bool? ?? false,
            );
          }
          break;
      }
    } catch (e) {
      _log("Error parsing incoming package: $e");
    }
  }

  /// Sends a raw asset file base64 encoded
  Future<void> _sendAssetFile(String relativePath) async {
    try {
      final file = File(relativePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64String = base64.encode(bytes);
        sendData({
          "type": "asset_payload",
          "path": relativePath,
          "bytes": base64String,
        });
      }
    } catch (e) {
      _log("Failed to send asset $relativePath: $e");
    }
  }

  /// Receives asset file bytes and writes them to workspace
  Future<void> _receiveAssetFile(String relativePath, String base64String) async {
    await Future.delayed(Duration.zero);
    try {
      final bytes = base64.decode(base64String);
      final file = File(relativePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(bytes);
      _log("Successfully synced asset file: $relativePath");
    } catch (e) {
      _log("Failed to write synced asset $relativePath: $e");
    }
  }

  void _log(String msg) {
    if (onLog != null) {
      onLog!("[P2P] $msg");
    }
  }
}
