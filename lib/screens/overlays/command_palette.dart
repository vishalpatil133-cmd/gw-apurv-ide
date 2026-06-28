import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({Key? key}) : super(key: key);

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = "";

  final List<Map<String, dynamic>> _commands = [
    {
      "name": "Zoom In: Increase Editor Font Size",
      "action": (BuildContext context, IdeProvider provider) {
        provider.increaseFontSize();
      }
    },
    {
      "name": "Zoom Out: Decrease Editor Font Size",
      "action": (BuildContext context, IdeProvider provider) {
        provider.decreaseFontSize();
      }
    },
    {
      "name": "Run: Build Cloud APK Package",
      "action": (BuildContext context, IdeProvider provider) {
        provider.buildApk();
      }
    },
    {
      "name": "Agent: Spawn Security Auditor Agent",
      "action": (BuildContext context, IdeProvider provider) {
        provider.triggerAgent("Security Auditor Agent", "main.dart");
      }
    },
    {
      "name": "Agent: Spawn UI Optimizer Agent",
      "action": (BuildContext context, IdeProvider provider) {
        provider.triggerAgent("UI Optimizer Agent", "main.dart");
      }
    },
    {
      "name": "Terminal: Clear Console logs",
      "action": (BuildContext context, IdeProvider provider) {
        provider.terminal.write('\x1b[2J\x1b[H');
      }
    },
    {
      "name": "Preferences: Open configuration settings panel",
      "action": (BuildContext context, IdeProvider provider) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      }
    },
    {
      "name": "Workspace: Refresh directories",
      "action": (BuildContext context, IdeProvider provider) {
        provider.refreshFiles();
      }
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    final filteredCommands = _commands.where((cmd) {
      return cmd["name"].toString().toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double availableHeight = screenHeight - keyboardHeight;
    final double paletteMaxHeight = (availableHeight * 0.85).clamp(100.0, 280.0);

    return Material(
      color: Colors.black.withOpacity(0.5), // Semi-transparent overlay background
      child: Center(
        child: Container(
          width: 500, // Fixed width desktop-style layout
          constraints: BoxConstraints(maxHeight: paletteMaxHeight),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neonCyan, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Gutter
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textPrimary),
                  onChanged: (val) {
                    setState(() {
                      _filter = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Type a command to execute...",
                    hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.chevron_right, color: AppColors.neonCyan, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      onPressed: () => provider.setCommandPaletteOpen(false),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Commands list
              Expanded(
                child: filteredCommands.isEmpty
                    ? const Center(
                        child: Text(
                          "No matching commands found.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredCommands.length,
                        itemBuilder: (context, index) {
                          final cmd = filteredCommands[index];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              cmd["name"],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: const Icon(Icons.keyboard_arrow_right, size: 12, color: AppColors.textSecondary),
                            hoverColor: Colors.white.withOpacity(0.05),
                            onTap: () {
                              provider.setCommandPaletteOpen(false);
                              cmd["action"](context, provider);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
