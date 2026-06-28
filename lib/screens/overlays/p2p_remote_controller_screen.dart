import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';

class P2PRemoteControllerScreen extends StatefulWidget {
  const P2PRemoteControllerScreen({Key? key}) : super(key: key);

  @override
  State<P2PRemoteControllerScreen> createState() => _P2PRemoteControllerScreenState();
}

class _P2PRemoteControllerScreenState extends State<P2PRemoteControllerScreen> {
  final TextEditingController _keyboardInputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _remoteCtrl = false;
  bool _remoteShift = false;
  bool _remoteAlt = false;

  @override
  void dispose() {
    _keyboardInputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    return Scaffold(
      backgroundColor: provider.editorBackgroundColor,
      appBar: AppBar(
        title: Text(
          "P2P REMOTE TOUCHPAD",
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: provider.neonCyanColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard, color: AppColors.neonPurple),
            onPressed: () {
              _focusNode.requestFocus();
            },
            tooltip: "Open Keyboard",
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.neonPink),
            onPressed: () {
              provider.stopP2PSession();
              Navigator.of(context).pop();
            },
            tooltip: "Disconnect Remote",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Invisible text field to capture keystrokes from native keyboard
          Positioned(
            left: -100,
            width: 10,
            height: 10,
            child: TextField(
              focusNode: _focusNode,
              controller: _keyboardInputController,
              autofocus: true,
              onChanged: (text) {
                if (text.isNotEmpty) {
                  // Send typed text keystrokes to Host
                  provider.p2pService.sendData({
                    "type": "keyboard_input",
                    "text": text,
                  });
                  _keyboardInputController.clear();
                }
              },
            ),
          ),
          
          // Large Trackpad Area
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) {
                        // Send mouse delta moves to Host
                        provider.p2pService.sendData({
                          "type": "mouse_move",
                          "dx": details.delta.dx,
                          "dy": details.delta.dy,
                        });
                      },
                      onTap: () {
                        // Send tap click
                        provider.p2pService.sendData({
                          "type": "mouse_click",
                        });
                      },
                      onDoubleTap: () {
                        // Send double tap selection
                        provider.p2pService.sendData({
                          "type": "mouse_double_click",
                        });
                      },
                      onLongPress: () {
                        // Send long press context action
                        provider.p2pService.sendData({
                          "type": "mouse_long_press",
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: provider.sidebarBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: provider.borderColor, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 64, color: provider.neonCyanColor.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                "DRAG TO MOVE REMOTE CURSOR",
                                style: GoogleFonts.outfit(fontSize: 10, color: provider.textSecondaryColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "TAP: CLICK  |  DOUBLE-TAP: SELECT  |  LONG-PRESS: RIGHT CLICK",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 8, color: provider.textSecondaryColor.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sensitivity Slider Row
                  Row(
                    children: [
                      Text(
                        "SPEED: ",
                        style: GoogleFonts.outfit(fontSize: 8, color: provider.textSecondaryColor, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.virtualMouseSensitivity,
                          min: 0.2,
                          max: 3.0,
                          divisions: 14,
                          activeColor: provider.neonCyanColor,
                          inactiveColor: provider.borderColor,
                          onChanged: (val) {
                            provider.setVirtualMouseSensitivity(val);
                          },
                        ),
                      ),
                      Text(
                        "${provider.virtualMouseSensitivity.toStringAsFixed(1)}x",
                        style: GoogleFonts.jetBrainsMono(fontSize: 8, color: provider.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Virtual Modifiers Helper Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModifierButton("CTRL", _remoteCtrl, (val) {
                        setState(() => _remoteCtrl = val);
                        provider.p2pService.sendData({
                          "type": "modifier_change",
                          "ctrl": _remoteCtrl,
                          "shift": _remoteShift,
                          "alt": _remoteAlt,
                        });
                      }, provider),
                      _buildModifierButton("SHIFT", _remoteShift, (val) {
                        setState(() => _remoteShift = val);
                        provider.p2pService.sendData({
                          "type": "modifier_change",
                          "ctrl": _remoteCtrl,
                          "shift": _remoteShift,
                          "alt": _remoteAlt,
                        });
                      }, provider),
                      _buildModifierButton("ALT", _remoteAlt, (val) {
                        setState(() => _remoteAlt = val);
                        provider.p2pService.sendData({
                          "type": "modifier_change",
                          "ctrl": _remoteCtrl,
                          "shift": _remoteShift,
                          "alt": _remoteAlt,
                        });
                      }, provider),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Connected to Host. Sync Status: Active. Latency: ${provider.p2pLatency}ms",
                    style: TextStyle(color: provider.textSecondaryColor, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierButton(String label, bool isActive, Function(bool) onChanged, IdeProvider provider) {
    return TextButton(
      onPressed: () => onChanged(!isActive),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? provider.neonCyanColor : provider.sidebarBgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: isActive ? provider.neonCyanColor : provider.borderColor),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.black : provider.textPrimaryColor,
        ),
      ),
    );
  }
}
