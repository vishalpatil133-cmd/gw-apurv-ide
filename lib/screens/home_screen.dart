import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/ide_provider.dart';
import '../theme/app_theme.dart';
import 'panes/explorer_pane.dart';
import 'panes/editor_pane.dart';
import 'panes/agent_terminal_pane.dart';
import 'overlays/command_palette.dart';
import 'overlays/planning_overlay.dart';
import 'overlays/p2p_collaboration_dialog.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final bool isVerticalEditor = provider.isVerticalEditorMode;
    final bool showLeftPane = !isVerticalEditor && screenWidth > 480 && provider.leftPaneWidth > 0 && !isKeyboardVisible;
    final bool showRightPane = !isVerticalEditor && screenWidth > 580 && provider.rightPaneWidth > 0 && !isKeyboardVisible;

    // Focusable keyboard listener to capture physical 'F1' keypresses
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f1) {
          provider.setCommandPaletteOpen(!provider.isCommandPaletteOpen);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: provider.editorBackgroundColor,
        body: Stack(
          children: [
            // Core Three-Pane Workspace Layout
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                // Top Global Status bar
                Container(
                  height: 24,
                  color: provider.sidebarBgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                height: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.fullAiMode
                                    ? "GW APURV IDE  |  FULL AI MODE"
                                    : "GW APURV IDE  |  SMART TV CASTING SERVICE ACTIVE",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: provider.textPrimaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (!provider.fullAiMode) ...[
                            if (provider.isP2PConnected) ...[
                              _buildStatusIndicator("P2P Status: ${provider.p2pStatus} (${provider.p2pLatency}ms)", provider.neonGreenColor, provider),
                              const SizedBox(width: 16),
                            ],
                            if (provider.remoteCtrlActive) ...[
                              _buildModifierPill("CTRL", provider),
                              const SizedBox(width: 6),
                            ],
                            if (provider.remoteShiftActive) ...[
                              _buildModifierPill("SHIFT", provider),
                              const SizedBox(width: 6),
                            ],
                            if (provider.remoteAltActive) ...[
                              _buildModifierPill("ALT", provider),
                              const SizedBox(width: 6),
                            ],
                            if (provider.remoteCtrlActive || provider.remoteShiftActive || provider.remoteAltActive)
                              const SizedBox(width: 10),
                            _buildStatusIndicator("Build Status: ${provider.isBuilding ? 'COMPILING' : 'IDLE'}",
                                provider.isBuilding ? provider.warningColor : provider.textSecondaryColor, provider),
                            const SizedBox(width: 16),
                            _buildStatusIndicator("Running Agents: ${provider.activeAgents.length}",
                                provider.activeAgents.isNotEmpty ? AppColors.neonPurple : provider.textSecondaryColor, provider),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                provider.setCommandPaletteOpen(true);
                              },
                              onLongPress: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.terminal,
                                    size: 11,
                                    color: provider.neonCyanColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "F1 ANCHOR",
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: provider.neonCyanColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                Icons.wifi_tethering,
                                size: 14,
                                color: (provider.isP2PHosting || provider.isP2PConnected)
                                    ? provider.neonGreenColor
                                    : provider.textSecondaryColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const P2PCollaborationDialog(),
                                );
                              },
                              tooltip: "P2P Project Collaboration",
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                Icons.mouse,
                                size: 14,
                                color: provider.virtualMouseEnabled ? provider.neonGreenColor : provider.textSecondaryColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: provider.toggleVirtualMouse,
                              tooltip: "Virtual Mouse Mode",
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                Icons.terminal_outlined,
                                size: 14,
                                color: provider.neonGreenColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const TerminalScreen(),
                                  ),
                                );
                              },
                              tooltip: "Open Standalone Termux Terminal",
                            ),
                            const SizedBox(width: 16),
                          ],
                          IconButton(
                            icon: Icon(
                              provider.lightThemeActive ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              size: 14,
                              color: provider.neonCyanColor,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              provider.setLightThemeActive(!provider.lightThemeActive);
                            },
                            tooltip: "Toggle Light/Dark Theme",
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.setFullAiMode(!provider.fullAiMode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider.fullAiMode ? provider.neonGreenColor.withOpacity(0.15) : provider.cardBgColor,
                              foregroundColor: provider.fullAiMode ? provider.neonGreenColor : provider.textSecondaryColor,
                              side: BorderSide(
                                color: provider.fullAiMode ? provider.neonGreenColor : provider.borderColor,
                                width: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            icon: Icon(
                              Icons.psychology,
                              size: 13,
                              color: provider.fullAiMode ? provider.neonGreenColor : provider.textSecondaryColor,
                            ),
                            label: Text(
                              provider.fullAiMode ? "EXIT FULL AI" : "FULL AI",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Divider(color: provider.borderColor, height: 1),

                // Main split pane row
                Expanded(
                  child: Row(
                    children: [
                      if (provider.fullAiMode && !isVerticalEditor)
                        const Expanded(
                          child: AgentTerminalPane(),
                        )
                      else ...[
                        if (showLeftPane) ...[
                          SizedBox(
                            width: provider.leftPaneWidth.clamp(0.0, screenWidth * 0.4),
                            child: const ClipRect(child: ExplorerPane()),
                          ),
                          // Resizable border divider 1
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              provider.adjustLeftPaneWidth(details.delta.dx, screenWidth);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: Container(
                                width: 12.0,
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: 3.5,
                                    color: provider.borderColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Pane 2: Monaco Editor (Center: Auto-fills rest of space)
                        const Expanded(
                          child: EditorPane(),
                        ),

                        if (showRightPane) ...[
                          // Resizable border divider 2
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              provider.adjustRightPaneWidth(-details.delta.dx, screenWidth);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: Container(
                                width: 12.0,
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: 3.5,
                                    color: provider.borderColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: provider.rightPaneWidth.clamp(0.0, screenWidth * 0.4),
                            child: const ClipRect(child: AgentTerminalPane()),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),



            // Overlay 1: Global F1 Command Palette Dialog
            if (provider.isCommandPaletteOpen)
              const Positioned.fill(
                child: CommandPalette(),
              ),

            // Overlay 2: Planning Mode Outlines
            if (provider.isPlanningActive)
              const Positioned.fill(
                child: PlanningOverlay(),
              ),

            // Overlay 3: Virtual Mouse Trackpad & Pointer Cursor
            if (provider.virtualMouseEnabled) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    final bounds = MediaQuery.of(context).size;
                    provider.updateVirtualMousePosition(details.delta, bounds);
                  },
                  onTap: () {
                    provider.triggerVirtualMouseClick();
                  },
                  onDoubleTap: () {
                    provider.triggerVirtualMouseDoubleClick();
                  },
                  onLongPress: () {
                    provider.triggerVirtualMouseLongPress();
                  },
                ),
              ),
              Positioned(
                left: provider.virtualMousePos.dx,
                top: provider.virtualMousePos.dy,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.785,
                    alignment: Alignment.topLeft,
                    child: Icon(
                      Icons.navigation,
                      size: 20,
                      color: provider.neonCyanColor,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ),
              ),
              if (provider.mouseRipplePos != null)
                Positioned(
                  left: provider.mouseRipplePos!.dx - 20,
                  top: provider.mouseRipplePos!.dy - 20,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 350),
                      builder: (context, value, child) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: provider.neonCyanColor.withOpacity(1.0 - value),
                              width: 1.5 + (2.5 * (1.0 - value)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],

            // Workspace Selection Blocking Overlay (on first launch / when no workspace is selected)
            if (!provider.hasWorkspaceSelected)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: provider.cardBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: provider.neonCyanColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: provider.neonCyanColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _WorkspaceSelectionDialog(provider: provider),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, IdeProvider provider) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 8,
            color: provider.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModifierPill(String label, IdeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: provider.neonCyanColor.withOpacity(0.15),
        border: Border.all(color: provider.neonCyanColor.withOpacity(0.8), width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 8,
          color: provider.neonCyanColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WorkspaceSelectionDialog extends StatelessWidget {
  final IdeProvider provider;
  const _WorkspaceSelectionDialog({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController folderController = TextEditingController(text: "MyGWWorkspace");
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 64,
        ),
        const SizedBox(height: 16),
        Text(
          "WELCOME TO GW IDE",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: provider.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "पहिले तुमच्या प्रोजेक्टसाठी एक फोल्डर निवडा किंवा तयार करा.",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: provider.textSecondaryColor,
            fontSize: 10,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              String? selectedDirectory = await FilePicker.getDirectoryPath();
              if (selectedDirectory != null) {
                await provider.selectWorkspacePath(selectedDirectory);
              }
            } catch (e) {
              provider.writeToTerminal("Directory picker error: $e\r\n");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: provider.neonPinkColor,
                  content: Text("Picker not supported: $e", style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              );
            }
          },
          icon: const Icon(Icons.folder_open, size: 14),
          label: Text(
            "CHOOSE FOLDER FROM PHONE",
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: provider.neonCyanColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: provider.borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "OR CREATE SANDBOX",
                style: TextStyle(color: provider.textSecondaryColor, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Divider(color: provider.borderColor)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: folderController,
          style: TextStyle(color: provider.textPrimaryColor, fontSize: 11, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: "Sandbox Folder Name",
            labelStyle: TextStyle(color: provider.textSecondaryColor, fontSize: 10),
            prefixIcon: Icon(Icons.folder, color: provider.neonCyanColor, size: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: provider.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: provider.neonCyanColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            final name = folderController.text.trim();
            if (name.isNotEmpty) {
              provider.selectWorkspace(name);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: provider.neonCyanColor,
            elevation: 0,
            side: BorderSide(color: provider.neonCyanColor, width: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            "OPEN SANDBOX WORKSPACE",
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

