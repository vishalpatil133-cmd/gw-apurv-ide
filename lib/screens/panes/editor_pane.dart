import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:path/path.dart' as p;
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';
import '../terminal_screen.dart';

class EditorPane extends StatelessWidget {
  const EditorPane({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    if (provider.selectedFilePath == null) {
      return Container(
        color: provider.editorBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: 48, color: provider.textSecondaryColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                "NO FILE OPEN",
                style: GoogleFonts.outfit(
                  color: provider.textPrimaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Open a file from the explorer list on the left.",
                style: TextStyle(color: provider.textSecondaryColor, fontSize: 10),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      color: provider.editorBackgroundColor,
      child: Column(
        children: [
          // Monaco Style Tab Bar (Up to 4 Tabs)
          Container(
            height: 28,
            color: provider.sidebarBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.openTabs.map((tabPath) {
                        final isTabActive = provider.selectedFilePath == tabPath;
                        final tabName = p.basename(tabPath);
                        return GestureDetector(
                          onTap: () => provider.openFile(tabPath),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isTabActive
                                  ? provider.editorBackgroundColor
                                  : provider.sidebarBgColor,
                              border: Border(
                                top: BorderSide(
                                  color: isTabActive
                                      ? provider.neonCyanColor
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                                right: BorderSide(
                                  color: provider.borderColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.code,
                                  size: 11,
                                  color: isTabActive
                                      ? provider.neonCyanColor
                                      : provider.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tabName,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: isTabActive
                                        ? provider.textPrimaryColor
                                        : provider.textSecondaryColor,
                                    fontSize: 10,
                                    fontWeight: isTabActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (provider.unsavedFiles.contains(tabPath)) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: provider.neonPinkColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                // Close Tab Button
                                GestureDetector(
                                  onTap: () {
                                    if (provider.unsavedFiles.contains(tabPath)) {
                                      _showCloseTabConfirmationDialog(context, provider, tabPath);
                                    } else {
                                      provider.closeTab(tabPath);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.close,
                                      size: 10,
                                      color: isTabActive
                                          ? provider.textPrimaryColor.withOpacity(0.6)
                                          : provider.textSecondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Editor Controls (Zoom, Save, Info)
                Row(
                  children: [
                    // Zoom Out
                    IconButton(
                      icon: Icon(Icons.zoom_out, size: 13, color: provider.textSecondaryColor),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: provider.decreaseFontSize,
                      tooltip: "Zoom Out (Smaller)",
                    ),
                    // Display font size indicator
                    Text(
                      "${provider.editorFontSize.toInt()}px",
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, color: provider.textSecondaryColor),
                    ),
                    // Zoom In
                    IconButton(
                      icon: Icon(Icons.zoom_in, size: 13, color: provider.textSecondaryColor),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: provider.increaseFontSize,
                      tooltip: "Zoom In (TV Cast)",
                    ),
                    VerticalDivider(color: provider.borderColor, width: 1),
                    // Manual Save Indicator
                    IconButton(
                      icon: provider.isSaving
                          ? SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(color: provider.neonCyanColor, strokeWidth: 1.5),
                            )
                          : Icon(Icons.save_outlined, size: 13, color: provider.neonCyanColor),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: provider.saveCurrentFile,
                      tooltip: "Save File (Ctrl+S)",
                    ),
                    VerticalDivider(color: provider.borderColor, width: 1),
                    // Run script action button
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.greenAccent),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () {
                        provider.runActiveFile();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TerminalScreen(),
                          ),
                        );
                      },
                      tooltip: "Run Script / Program (C/C++/Python)",
                    ),
                    VerticalDivider(color: provider.borderColor, width: 1),
                    // Full Screen Editor / Orientation Toggle
                    IconButton(
                      icon: Icon(
                        provider.isVerticalEditorMode ? Icons.fullscreen_exit : Icons.fullscreen,
                        size: 15,
                        color: provider.neonCyanColor,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () {
                        provider.toggleVerticalEditorMode(!provider.isVerticalEditorMode);
                      },
                      tooltip: provider.isVerticalEditorMode
                          ? "Exit Full Screen (Landscape)"
                          : "Full Screen Editor (Portrait)",
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Warning banner if Python support is missing
          if (provider.selectedFilePath != null &&
              provider.selectedFilePath!.endsWith('.py') &&
              !provider.marketplaceExtensions.any((ext) => ext.name == "Python Language Support" && ext.isInstalled))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: provider.warningColor.withOpacity(0.15),
                border: Border(bottom: BorderSide(color: provider.warningColor)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: provider.warningColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Python Language Support extension is required to enable syntax highlighting for Python files.",
                      style: GoogleFonts.outfit(color: provider.warningColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        final ext = provider.marketplaceExtensions.firstWhere((e) => e.name == "Python Language Support");
                        provider.installExtension(ext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.warningColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        "INSTALL NOW",
                        style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),

          // Real Extensions tool bar (if any are active)
          _buildExtensionsToolBar(context, provider),

          // Main Editor surface with Git Lens gutter indicators
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simulated Native Git Lens revision indicator gutter
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: provider.sidebarBgColor,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(height: 40, color: provider.neonGreenColor), // Line additions
                        Container(height: 60, color: Colors.transparent),
                        Container(height: 20, color: provider.warningColor), // Line edits
                        Container(height: 80, color: Colors.transparent),
                        Container(height: 10, color: provider.neonPinkColor), // Line deletions
                      ],
                    ),
                  ),
                ),

                // Core Code text field
                Expanded(
                  child: CodeTheme(
                    data: CodeThemeData(
                      styles: provider.lightThemeActive
                          ? githubTheme
                          : (provider.isDraculaActive ? draculaTheme : monokaiSublimeTheme),
                    ),
                    child: CodeField(
                      controller: provider.codeController,
                      textStyle: GoogleFonts.jetBrainsMono(
                        fontSize: provider.editorFontSize,
                        height: 1.3,
                      ),
                      lineNumberStyle: LineNumberStyle(
                        width: 48.0,
                        margin: 6.0,
                        textAlign: TextAlign.right,
                        textStyle: GoogleFonts.jetBrainsMono(
                          fontSize: provider.editorFontSize * 0.85,
                          color: provider.textSecondaryColor.withOpacity(0.5),
                        ),
                      ),
                      lineNumbers: true,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Problems Panel (Animates height based on syntax errors presence)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: provider.syntaxProblems.isNotEmpty
                ? (provider.problemsDismissed ? 22.0 : 100.0)
                : 0.0,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: provider.editorBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: provider.syntaxProblems.isNotEmpty ? provider.borderColor : Colors.transparent,
                  width: provider.syntaxProblems.isNotEmpty ? 1.0 : 0.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    provider.setProblemsDismissed(!provider.problemsDismissed);
                  },
                  child: Container(
                    height: 22,
                    color: provider.sidebarBgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              "PROBLEMS (${provider.syntaxProblems.length})",
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          provider.problemsDismissed
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 14,
                          color: provider.textSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.syntaxProblems.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (context, idx) {
                      final prob = provider.syntaxProblems[idx];
                      return InkWell(
                        onTap: () {
                          final text = provider.codeController.text;
                          final lines = text.split('\n');
                          int offset = 0;
                          for (int i = 0; i < prob.line - 1; i++) {
                            if (i < lines.length) {
                              offset += lines[i].length + 1;
                            }
                          }
                          provider.codeController.selection = TextSelection.fromPosition(
                            TextPosition(offset: offset),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          child: Row(
                            children: [
                              Text(
                                "Ln ${prob.line}:",
                                style: GoogleFonts.jetBrainsMono(
                                  color: provider.textSecondaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  prob.message,
                                  style: TextStyle(
                                    color: provider.textPrimaryColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Smart Touch & Autocomplete Suggestion Toolbar
          _buildSmartTouchToolbar(context, provider),

          // Firebase-style mini status bar
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            Container(
              height: 16,
              color: provider.sidebarBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 9, color: provider.neonGreenColor),
                      const SizedBox(width: 4),
                      Text(
                        "Cloud Compiler Link: ACTIVE",
                        style: GoogleFonts.outfit(fontSize: 8, color: provider.textSecondaryColor),
                      ),
                    ],
                  ),
                  Text(
                    "UTF-8   |   Dart   |   Ln 12, Col 4",
                    style: GoogleFonts.outfit(fontSize: 8, color: provider.textSecondaryColor),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCloseTabConfirmationDialog(BuildContext context, IdeProvider provider, String tabPath) {
    final fileName = p.basename(tabPath);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: provider.cardBgColor,
          title: Text(
            "UNSAVED CHANGES",
            style: GoogleFonts.outfit(color: provider.warningColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          content: Text(
            "'$fileName' has unsaved changes. Do you want to save them before closing?",
            style: TextStyle(color: provider.textPrimaryColor, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text("CANCEL", style: TextStyle(color: provider.textSecondaryColor, fontSize: 11)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                provider.closeTab(tabPath, autoSave: false, revert: true); // Discard
              },
              child: Text("DISCARD", style: TextStyle(color: provider.neonPinkColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (provider.selectedFilePath == tabPath) {
                  await provider.saveCurrentFile();
                }
                await provider.closeTab(tabPath, autoSave: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: provider.neonGreenColor),
              child: const Text("SAVE & CLOSE", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartTouchToolbar(BuildContext context, IdeProvider provider) {
    if (provider.selectedFilePath == null) return const SizedBox();

    final ext = p.extension(provider.selectedFilePath!).toLowerCase();
    List<String> suggestions = [];
    if (ext == '.dart') {
      suggestions = ['import', 'class', 'void', 'return', 'Widget', 'BuildContext', 'StatefulWidget', 'StatelessWidget', 'Scaffold', 'MaterialApp', 'Colors', 'final', 'const', 'int', 'double', 'String', 'bool'];
    } else if (ext == '.py') {
      suggestions = ['import', 'def', 'class', 'self', 'print', 'return', 'if __name__ == \'__main__\':', 'try', 'except', 'final', 'int', 'str', 'list', 'dict'];
    } else if (ext == '.c' || ext == '.cpp') {
      suggestions = ['#include <stdio.h>', '#include <iostream>', 'int main()', 'printf', 'std::cout', 'return 0;', 'using namespace std;', 'char', 'int', 'double', 'void'];
    } else {
      suggestions = ['import', 'class', 'return', 'void', 'final', 'const'];
    }

    // Merge dynamic suggestions (local functions, variables, classes) parsed via regex
    final dynamicSugs = provider.getDynamicSuggestions();
    suggestions = [...dynamicSugs, ...suggestions].toSet().toList();

    final List<String> symbolHelpers = ['{', '}', '(', ')', '[', ']', ';', '=', ':', ',', '"', '\'', '<', '>', '+', '-', '*', '/'];

    return Container(
      decoration: BoxDecoration(
        color: provider.sidebarBgColor,
        border: Border(
          top: BorderSide(color: provider.borderColor, width: 0.5),
          bottom: BorderSide(color: provider.borderColor, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions Row with Horizontal Scroll Chevrons
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_left, size: 14, color: provider.textSecondaryColor.withOpacity(0.4)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestions.map((sug) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          height: 22,
                          child: ElevatedButton(
                            onPressed: () {
                              provider.insertCodeAtCursor(sug);
                              provider.forceRecordHistory(provider.codeController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider.cardBgColor,
                              foregroundColor: provider.neonCyanColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: provider.borderColor, width: 0.5),
                              ),
                            ),
                            child: Text(
                              sug,
                              style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_right, size: 14, color: provider.textSecondaryColor.withOpacity(0.4)),
              ],
            ),
          ),
          
          Divider(height: 0.5, color: provider.borderColor),
          
          // Navigation & Quick Actions Row
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                // Undo / Redo
                IconButton(
                  icon: Icon(Icons.undo_rounded, size: 13, color: provider.canUndo ? provider.neonCyanColor : provider.textSecondaryColor.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: provider.canUndo ? provider.undo : null,
                  tooltip: "Undo",
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.redo_rounded, size: 13, color: provider.canRedo ? provider.neonCyanColor : provider.textSecondaryColor.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: provider.canRedo ? provider.redo : null,
                  tooltip: "Redo",
                ),
                
                VerticalDivider(color: provider.borderColor, width: 16),
                
                // Navigation Keys
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, size: 14, color: provider.neonCyanColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final controller = provider.codeController;
                    final selection = controller.selection;
                    if (selection.start > 0) {
                      controller.selection = TextSelection.collapsed(offset: selection.start - 1);
                    }
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.arrow_upward_rounded, size: 14, color: provider.neonCyanColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final controller = provider.codeController;
                    final text = controller.text;
                    final selection = controller.selection;
                    final currentOffset = selection.start;
                    if (currentOffset <= 0) return;
                    final lines = text.substring(0, currentOffset).split('\n');
                    if (lines.length <= 1) return;
                    final currentLineLength = lines.last.length;
                    final prevLineLength = lines[lines.length - 2].length;
                    int prevLineStart = 0;
                    for (int i = 0; i < lines.length - 2; i++) {
                      prevLineStart += lines[i].length + 1;
                    }
                    final targetCol = currentLineLength.clamp(0, prevLineLength);
                    controller.selection = TextSelection.collapsed(offset: prevLineStart + targetCol);
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.arrow_downward_rounded, size: 14, color: provider.neonCyanColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final controller = provider.codeController;
                    final text = controller.text;
                    final selection = controller.selection;
                    final currentOffset = selection.start;
                    final lines = text.split('\n');
                    final priorText = text.substring(0, currentOffset);
                    final priorLines = priorText.split('\n');
                    final currentLineIdx = priorLines.length - 1;
                    if (currentLineIdx >= lines.length - 1) return;
                    final currentLineCol = priorLines.last.length;
                    final nextLineLength = lines[currentLineIdx + 1].length;
                    int nextLineStart = 0;
                    for (int i = 0; i <= currentLineIdx; i++) {
                      nextLineStart += lines[i].length + 1;
                    }
                    final targetCol = currentLineCol.clamp(0, nextLineLength);
                    controller.selection = TextSelection.collapsed(offset: nextLineStart + targetCol);
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.arrow_forward_rounded, size: 14, color: provider.neonCyanColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final controller = provider.codeController;
                    final selection = controller.selection;
                    if (selection.start < controller.text.length) {
                      controller.selection = TextSelection.collapsed(offset: selection.start + 1);
                    }
                  },
                ),
                
                VerticalDivider(color: provider.borderColor, width: 16),
                
                // Symbol quick helper row with Horizontal Scroll Chevrons
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_arrow_left, size: 14, color: provider.textSecondaryColor.withOpacity(0.4)),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: symbolHelpers.map((sym) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: TextButton(
                                    onPressed: () {
                                      provider.insertCodeAtCursor(sym);
                                      provider.forceRecordHistory(provider.codeController.text);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: provider.cardBgColor,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        side: BorderSide(color: provider.borderColor, width: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      sym,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        color: provider.textPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right, size: 14, color: provider.textSecondaryColor.withOpacity(0.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionsToolBar(BuildContext context, IdeProvider provider) {
    final hasSnippets = provider.marketplaceExtensions.any((ext) => ext.name == "Flutter Snippets" && ext.isInstalled);
    final hasCopilot = provider.marketplaceExtensions.any((ext) => ext.name == "GitHub Copilot Sim" && ext.isInstalled);

    if (!hasSnippets && !hasCopilot) return const SizedBox();

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: provider.cardBgColor,
        border: Border(bottom: BorderSide(color: provider.borderColor)),
      ),
      child: Row(
        children: [
          if (hasSnippets) ...[
            Icon(Icons.snippet_folder, size: 12, color: provider.neonCyanColor),
            const SizedBox(width: 4),
            Text(
              "SNIPPETS:",
              style: GoogleFonts.outfit(fontSize: 8, color: provider.textSecondaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            _buildSnippetButton(
              label: "stless",
              tooltip: "StatelessWidget template",
              snippet: '''class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}''',
              provider: provider,
            ),
            _buildSnippetButton(
              label: "stful",
              tooltip: "StatefulWidget template",
              snippet: '''class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}''',
              provider: provider,
            ),
            _buildSnippetButton(
              label: "initS",
              tooltip: "initState() block",
              snippet: '''@override
void initState() {
  super.initState();
  // TODO: implement initState
}''',
              provider: provider,
            ),
            const SizedBox(width: 8),
            if (hasCopilot) VerticalDivider(color: provider.borderColor, width: 1, indent: 6, endIndent: 6),
            const SizedBox(width: 8),
          ],
          if (hasCopilot) ...[
            Icon(Icons.psychology, size: 12, color: provider.neonGreenColor),
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: ElevatedButton.icon(
                onPressed: provider.isCopilotLoading ? null : provider.triggerCopilotSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.neonGreenColor.withOpacity(0.15),
                  foregroundColor: provider.neonGreenColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: provider.neonGreenColor.withOpacity(0.3)),
                  ),
                ),
                icon: provider.isCopilotLoading
                    ? const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.green),
                      )
                    : const Icon(Icons.bolt, size: 10),
                label: Text(
                  "COPILOT SUGGEST",
                  style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildSnippetButton({
    required String label,
    required String tooltip,
    required String snippet,
    required IdeProvider provider,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      height: 20,
      child: TextButton(
        onPressed: () => provider.insertCodeAtCursor(snippet),
        style: TextButton.styleFrom(
          backgroundColor: provider.sidebarBgColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: provider.borderColor, width: 0.5),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Tooltip(
          message: tooltip,
          textStyle: const TextStyle(fontSize: 9),
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: provider.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
