import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class ExplorerPane extends StatelessWidget {
  const ExplorerPane({Key? key}) : super(key: key);

  void _showCreateFileDialog(BuildContext context, IdeProvider provider) {
    final TextEditingController fileController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(
            "NEW WORKSPACE FILE",
            style: GoogleFonts.outfit(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          content: TextField(
            controller: fileController,
            autofocus: true,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: "e.g. main.dart, index.html",
              hintStyle: TextStyle(fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = fileController.text.trim();
                if (name.isNotEmpty) {
                  provider.createNewFile(name);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
              child: const Text("CREATE", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, IdeProvider provider, String oldPath) {
    final TextEditingController renameController = TextEditingController(text: p.basename(oldPath));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: provider.cardBgColor,
          title: Text(
            "RENAME FILE/FOLDER",
            style: GoogleFonts.outfit(color: provider.neonCyanColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          content: TextField(
            controller: renameController,
            autofocus: true,
            style: TextStyle(fontSize: 12, color: provider.textPrimaryColor),
            decoration: InputDecoration(
              hintText: "New name",
              hintStyle: TextStyle(fontSize: 11, color: provider.textSecondaryColor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("CANCEL", style: TextStyle(color: provider.textSecondaryColor, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = renameController.text.trim();
                if (name.isNotEmpty && name != p.basename(oldPath)) {
                  provider.renameFile(oldPath, name);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: provider.neonCyanColor),
              child: const Text("RENAME", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, IdeProvider provider, String filePath) {
    final name = p.basename(filePath);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: provider.cardBgColor,
          title: Text(
            "DELETE CONFIRMATION",
            style: GoogleFonts.outfit(color: provider.neonPinkColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          content: Text(
            "Are you sure you want to permanently delete '$name'?",
            style: TextStyle(color: provider.textPrimaryColor, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("CANCEL", style: TextStyle(color: provider.textSecondaryColor, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteFile(filePath);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: provider.neonPinkColor),
              child: const Text("DELETE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: provider.sidebarBgColor,
        border: Border(right: BorderSide(color: provider.borderColor)),
      ),
      child: Row(
        children: [
          // Activity Bar (Vertical Strip)
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF131314),
              border: Border(right: BorderSide(color: provider.borderColor)),
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildActivityIcon(
                          Icons.insert_drive_file,
                          "Explorer",
                          active: provider.activeLeftTab == LeftSidebarTab.explorer,
                          onTap: () => provider.setLeftTab(LeftSidebarTab.explorer),
                        ),
                        _buildActivityIcon(
                          Icons.grid_view_outlined,
                          "Extensions Marketplace",
                          active: provider.activeLeftTab == LeftSidebarTab.extensionMarketplace,
                          onTap: () => provider.setLeftTab(LeftSidebarTab.extensionMarketplace),
                        ),
                        _buildActivityIcon(
                          Icons.psychology,
                          "AI Agents",
                          active: false,
                          onTap: () => provider.setRightTab(RightPaneTab.agentManager),
                        ),
                        _buildActivityIcon(
                          Icons.terminal,
                          "Terminal",
                          active: false,
                          onTap: () => provider.setRightTab(RightPaneTab.terminal),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _buildActivityIcon(
                          Icons.search,
                          "Command Palette (F1)",
                          active: false,
                          onTap: () => provider.setCommandPaletteOpen(true),
                        ),
                        _buildActivityIcon(Icons.settings, "Settings", active: false, onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sliding Left Side Pane
          Expanded(
            child: !provider.hasWorkspaceSelected
                ? _buildWorkspaceSelector(context, provider)
                : (provider.activeLeftTab == LeftSidebarTab.explorer
                    ? _buildFileExplorer(context, provider)
                    : _buildExtensionMarketplace(context, provider)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSelector(BuildContext context, IdeProvider provider) {
    final TextEditingController folderController = TextEditingController(text: "GWWorkspace");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "CHOOSE WORKSPACE",
            style: GoogleFonts.outfit(
              color: provider.textPrimaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Divider(color: provider.borderColor, height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.folder_open_rounded,
                  size: 44,
                  color: provider.neonCyanColor,
                ),
                const SizedBox(height: 12),
                Text(
                  "Choose a folder on your phone to set as your project workspace.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: provider.textPrimaryColor,
                    fontSize: 11,
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
                  icon: const Icon(Icons.folder, size: 14),
                  label: Text(
                    "CHOOSE FOLDER FROM PHONE",
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.neonCyanColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: provider.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "OR USE SANDBOX WORKSPACE",
                        style: TextStyle(color: provider.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Divider(color: provider.borderColor)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: folderController,
                  style: TextStyle(fontSize: 11, color: provider.textPrimaryColor, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: "Sandbox Folder Name",
                    labelStyle: TextStyle(fontSize: 10, color: provider.textSecondaryColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: provider.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: provider.neonCyanColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: provider.borderColor),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    "OPEN SANDBOX WORKSPACE",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileExplorer(BuildContext context, IdeProvider provider) {
    final filteredFiles = provider.files.where((entity) {
      final name = p.basename(entity.path);
      return name.toLowerCase().contains(provider.explorerFilter.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "EXPLORER",
                style: GoogleFonts.outfit(
                  color: provider.textPrimaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 14, color: provider.neonCyanColor),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showCreateFileDialog(context, provider),
                    tooltip: "New File",
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 14, color: provider.textSecondaryColor),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: provider.refreshFiles,
                    tooltip: "Refresh Explorer",
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.folder_off_outlined, size: 14, color: provider.textSecondaryColor),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => provider.setWorkspaceSelected(false),
                    tooltip: "Close Workspace",
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(color: provider.borderColor, height: 1),

        // Search Filter Input
        Container(
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: TextField(
            onChanged: (val) => provider.setExplorerFilter(val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: provider.explorerFilter,
                selection: TextSelection.collapsed(offset: provider.explorerFilter.length),
              ),
            ),
            style: const TextStyle(fontSize: 10, color: Colors.white),
            decoration: InputDecoration(
              hintText: "Filter files...",
              hintStyle: TextStyle(fontSize: 10, color: provider.textSecondaryColor),
              prefixIcon: Icon(Icons.search, size: 12, color: provider.textSecondaryColor),
              suffixIcon: provider.explorerFilter.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        provider.setExplorerFilter("");
                      },
                      child: Icon(Icons.clear, size: 12, color: provider.textSecondaryColor),
                    )
                  : null,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: provider.borderColor, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: provider.neonCyanColor, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: provider.borderColor, width: 0.5),
              ),
            ),
          ),
        ),
        Divider(color: provider.borderColor, height: 1),

        // File List
        Expanded(
          child: provider.isWorkspaceLoading
              ? Center(child: CircularProgressIndicator(color: provider.neonCyanColor, strokeWidth: 2))
              : filteredFiles.isEmpty
                  ? Center(child: Text("No files found", style: TextStyle(color: provider.textSecondaryColor, fontSize: 10)))
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final entity = filteredFiles[index];
                    final name = p.basename(entity.path);
                    final isSelected = provider.selectedFilePath == entity.path;
                    final isDir = entity is Directory;

                    return InkWell(
                      onTap: () {
                        if (!isDir) {
                          provider.openFileInTab(entity.path);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              isDir ? Icons.folder : Icons.insert_drive_file_outlined,
                              color: isDir
                                  ? provider.neonCyanColor.withOpacity(0.8)
                                  : isSelected
                                      ? provider.neonGreenColor
                                      : provider.textSecondaryColor,
                              size: 11,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected ? provider.neonGreenColor : provider.textPrimaryColor,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected) ...[
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: provider.neonGreenColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 12,
                                color: provider.textSecondaryColor.withOpacity(0.7),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Options",
                              color: provider.cardBgColor,
                              onSelected: (action) {
                                if (action == 'rename') {
                                  _showRenameDialog(context, provider, entity.path);
                                } else if (action == 'delete') {
                                  _showDeleteConfirmDialog(context, provider, entity.path);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  height: 28,
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 11, color: provider.neonCyanColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Rename",
                                        style: TextStyle(fontSize: 10.5, color: provider.textPrimaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  height: 28,
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 11, color: provider.neonPinkColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Delete",
                                        style: TextStyle(fontSize: 10.5, color: provider.textPrimaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExtensionMarketplace(BuildContext context, IdeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "EXTENSIONS",
                style: GoogleFonts.outfit(
                  color: provider.textPrimaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.storefront, size: 14, color: provider.neonCyanColor),
            ],
          ),
        ),
        Divider(color: provider.borderColor, height: 1),

        // Extensions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            itemCount: provider.marketplaceExtensions.length,
            itemBuilder: (context, index) {
              final ext = provider.marketplaceExtensions[index];
              return Card(
                color: provider.cardBgColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: provider.borderColor, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ext.name,
                              style: GoogleFonts.outfit(
                                color: provider.neonCyanColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ext.version,
                            style: TextStyle(
                              color: provider.textSecondaryColor,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "by ${ext.publisher}",
                        style: TextStyle(
                          color: provider.textSecondaryColor,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ext.description,
                        style: TextStyle(
                          color: provider.textPrimaryColor,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                ext.rating.toString(),
                                style: TextStyle(fontSize: 9, color: provider.textPrimaryColor),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.download, color: provider.textSecondaryColor, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                "${(ext.downloads / 1000).toStringAsFixed(1)}k",
                                style: TextStyle(fontSize: 9, color: provider.textSecondaryColor),
                              ),
                            ],
                          ),
                          if (ext.isInstalling)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: provider.neonCyanColor,
                              ),
                            )
                          else if (ext.isInstalled)
                            ElevatedButton(
                              onPressed: () => provider.uninstallExtension(ext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.neonPinkColor.withOpacity(0.2),
                                foregroundColor: provider.neonPinkColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  side: BorderSide(color: provider.neonPinkColor, width: 0.5),
                                ),
                              ),
                              child: const Text("UNINSTALL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => provider.installExtension(ext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.neonGreenColor.withOpacity(0.2),
                                foregroundColor: provider.neonGreenColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  side: BorderSide(color: provider.neonGreenColor, width: 0.5),
                                ),
                              ),
                              child: const Text("INSTALL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityIcon(IconData icon, String tooltip, {required bool active, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: active ? const Border(left: BorderSide(color: AppColors.neonCyan, width: 2)) : null,
            ),
            child: Icon(
              icon,
              color: active ? AppColors.neonCyan : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
