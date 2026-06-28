import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xterm/xterm.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';
import 'marketplace_pane.dart';

class AgentTerminalPane extends StatefulWidget {
  const AgentTerminalPane({Key? key}) : super(key: key);

  @override
  State<AgentTerminalPane> createState() => _AgentTerminalPaneState();
}

class _AgentTerminalPaneState extends State<AgentTerminalPane> {
  late final TextEditingController _implKeyController;
  late final TextEditingController _execKeyController;
  late final TextEditingController _analKeyController;
  late final TextEditingController _chatController;
  bool _obscureApiKey = true;
  bool _isConfigCollapsed = true;
  bool _showConfigForced = false;

  @override
  void initState() {
    super.initState();
    _implKeyController = TextEditingController();
    _execKeyController = TextEditingController();
    _analKeyController = TextEditingController();
    _chatController = TextEditingController();

    // Set initial text from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<IdeProvider>(context, listen: false);
      _implKeyController.text = provider.implementationApiKey;
      _execKeyController.text = provider.executionApiKey;
      _analKeyController.text = provider.analysisApiKey;
      setState(() {
        _isConfigCollapsed = provider.executionApiKey.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _implKeyController.dispose();
    _execKeyController.dispose();
    _analKeyController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    // Sync from provider if modified elsewhere (e.g. settings screen)
    if (!FocusScope.of(context).hasFocus) {
      if (_implKeyController.text != provider.implementationApiKey) {
        _implKeyController.text = provider.implementationApiKey;
      }
      if (_execKeyController.text != provider.executionApiKey) {
        _execKeyController.text = provider.executionApiKey;
      }
      if (_analKeyController.text != provider.analysisApiKey) {
        _analKeyController.text = provider.analysisApiKey;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: provider.sidebarBgColor,
        border: Border(left: BorderSide(color: provider.borderColor)),
      ),
      child: Column(
        children: [
          if (provider.fullAiMode)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: provider.cardBgColor,
                border: Border(bottom: BorderSide(color: provider.borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, size: 14, color: provider.neonGreenColor),
                      const SizedBox(width: 6),
                      Text(
                        "FULL AI MODE ACTIVE",
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: provider.neonGreenColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: provider.neonCyanColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: provider.neonCyanColor, width: 0.5),
                        ),
                        child: Text(
                          provider.agentLanguage.split(' ').first.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: provider.neonCyanColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showConfigForced ? Icons.close_fullscreen : Icons.settings,
                          size: 13,
                          color: _showConfigForced ? provider.neonCyanColor : provider.textSecondaryColor,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          setState(() {
                            _showConfigForced = !_showConfigForced;
                          });
                        },
                        tooltip: _showConfigForced ? "Hide settings panel" : "Show settings panel",
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => provider.setFullAiMode(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: provider.neonPinkColor.withOpacity(0.15),
                          foregroundColor: provider.neonPinkColor,
                          side: BorderSide(
                            color: provider.neonPinkColor,
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
                          Icons.logout,
                          size: 11,
                          color: provider.neonPinkColor,
                        ),
                        label: Text(
                          "EXIT",
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Switch Tab Header
          if (!provider.fullAiMode)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: provider.sidebarBgColor,
                  border: Border(bottom: BorderSide(color: provider.borderColor)),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      title: "AGENT MANAGER HUB",
                      active: provider.activeRightTab == RightPaneTab.agentManager,
                      onTap: () => provider.setRightTab(RightPaneTab.agentManager),
                      provider: provider,
                    ),
                    _buildTabButton(
                      title: "TERMINAL CONSOLE",
                      active: provider.activeRightTab == RightPaneTab.terminal,
                      onTap: () => provider.setRightTab(RightPaneTab.terminal),
                      provider: provider,
                    ),
                    _buildTabButton(
                      title: "ARTIFACTS VIEW",
                      active: provider.activeRightTab == RightPaneTab.artifacts,
                      onTap: () => provider.setRightTab(RightPaneTab.artifacts),
                      provider: provider,
                    ),
                    _buildTabButton(
                      title: "MARKETPLACE",
                      active: provider.activeRightTab == RightPaneTab.marketplace,
                      onTap: () => provider.setRightTab(RightPaneTab.marketplace),
                      provider: provider,
                    ),
                  ],
                ),
              ),
            ),

          // Main Pane Content
          Expanded(
            child: _buildPaneContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
    required IdeProvider provider,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? provider.editorBackgroundColor : Colors.transparent,
          border: active
              ? Border(
                  bottom: BorderSide(color: provider.neonCyanColor, width: 2),
                )
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: active ? provider.neonCyanColor : provider.textSecondaryColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPaneContent(IdeProvider provider) {
    switch (provider.activeRightTab) {
      case RightPaneTab.agentManager:
        return _buildAgentManager(provider);
      case RightPaneTab.terminal:
        return _buildTerminal(provider);
      case RightPaneTab.artifacts:
        return _buildArtifacts(provider);
      case RightPaneTab.marketplace:
        return const MarketplacePane();
    }
  }

  // ==========================================
  // AGENT MANAGER HUB & CHAT
  // ==========================================
  Widget _buildAgentManager(IdeProvider provider) {

    List<Map<String, String>> getModelsForKey(String key) {
      final k = key.trim();
      if (k.startsWith("gsk_")) {
        return [
          {"value": "llama-3.3-70b-versatile", "label": "Llama 3.3 (Groq)"},
          {"value": "llama3-70b-8192", "label": "Llama 3 (Groq)"},
          {"value": "mixtral-8x7b-32768", "label": "Mixtral 8x7B (Groq)"},
          {"value": "gemma2-9b-it", "label": "Gemma 2 9B (Groq)"},
        ];
      } else if (k.startsWith("sk-")) {
        return [
          {"value": "google/gemini-2.5-flash:free", "label": "Gemini 2.5 (Free)"},
          {"value": "nvidia/nemotron-3-super-120b-a12b:free", "label": "Nemotron 3 (Free)"},
          {"value": "meta-llama/llama-3.3-70b-instruct:free", "label": "Llama 3.3 (Free)"},
          {"value": "deepseek/deepseek-chat:free", "label": "DeepSeek (Free)"},
          {"value": "qwen/qwen-2.5-coder-32b-instruct:free", "label": "Qwen 2.5 Coder (Free)"},
        ];
      } else if (k.startsWith("AIza") || k.startsWith("AI") || k.startsWith("AQ")) {
        return [
          {"value": "gemini-2.5-flash", "label": "gemini-2.5-flash"},
          {"value": "gemini-2.5-pro", "label": "gemini-2.5-pro"},
          {"value": "gemini-2.0-flash", "label": "gemini-2.0-flash"},
          {"value": "gemini-1.5-flash", "label": "gemini-1.5-flash"},
          {"value": "gemini-1.5-pro", "label": "gemini-1.5-pro"},
        ];
      } else {
        return [
          {"value": "gemini-2.5-flash", "label": "gemini-2.5-flash"},
          {"value": "gemini-2.5-pro", "label": "gemini-2.5-pro"},
          {"value": "gemini-2.0-flash", "label": "gemini-2.0-flash"},
          {"value": "gemini-1.5-flash", "label": "gemini-1.5-flash"},
          {"value": "gemini-1.5-pro", "label": "gemini-1.5-pro"},
          {"value": "google/gemini-2.5-flash:free", "label": "Gemini 2.5 (Free)"},
          {"value": "nvidia/nemotron-3-super-120b-a12b:free", "label": "Nemotron 3 (Free)"},
          {"value": "meta-llama/llama-3.3-70b-instruct:free", "label": "Llama 3.3 (Free)"},
          {"value": "deepseek/deepseek-chat:free", "label": "DeepSeek (Free)"},
          {"value": "qwen/qwen-2.5-coder-32b-instruct:free", "label": "Qwen 2.5 Coder (Free)"},
        ];
      }
    }

    final archModels = getModelsForKey(_implKeyController.text);
    final execModels = getModelsForKey(_execKeyController.text);
    final analModels = getModelsForKey(_analKeyController.text);
    final bool isConfigured = provider.geminiApiKey.isNotEmpty;
    final bool shouldHideConfig = isConfigured && !_showConfigForced;

    return Column(
      children: [
        if (!shouldHideConfig) ...[
          // API Key Section at the top (Tappable header to collapse/expand)
          GestureDetector(
            onTap: () {
              setState(() {
                _isConfigCollapsed = !_isConfigCollapsed;
              });
            },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: provider.cardBgColor,
                  border: Border(bottom: BorderSide(color: provider.borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(
                              Icons.vpn_key,
                              size: 14,
                              color: isConfigured ? provider.neonGreenColor : provider.neonPinkColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "GEMINI / OPENROUTER CONFIGURATION",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isConfigured
                                ? provider.neonGreenColor.withOpacity(0.15)
                                : provider.neonPinkColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isConfigured ? provider.neonGreenColor : provider.neonPinkColor,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            isConfigured ? "ACTIVE" : "OFFLINE",
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isConfigured ? provider.neonGreenColor : provider.neonPinkColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isConfigCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          size: 14,
                          color: provider.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ),

          // Animated collapsible fields panel
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isConfigCollapsed && isConfigured
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    color: provider.cardBgColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Field 1: Implementation Key (Groq)
                        SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _implKeyController,
                            obscureText: _obscureApiKey,
                            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: provider.neonCyanColor),
                            decoration: InputDecoration(
                              hintText: "Implementation Key (Groq - gsk_...)",
                              hintStyle: TextStyle(fontSize: 9.5, color: provider.textSecondaryColor),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              prefixIcon: Icon(Icons.psychology, size: 12, color: provider.neonPurpleColor),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.neonCyanColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Field 2: Execution Key (Gemini/OpenRouter)
                        SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _execKeyController,
                            obscureText: _obscureApiKey,
                            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: provider.neonCyanColor),
                            decoration: InputDecoration(
                              hintText: "Execution Key (Gemini / OpenRouter)",
                              hintStyle: TextStyle(fontSize: 9.5, color: provider.textSecondaryColor),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              prefixIcon: Icon(Icons.play_arrow, size: 12, color: provider.neonGreenColor),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.neonCyanColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Field 3: Analysis/Terminal Key
                        SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _analKeyController,
                            obscureText: _obscureApiKey,
                            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: provider.neonCyanColor),
                            decoration: InputDecoration(
                              hintText: "Analysis/Terminal Key (Gemini / OpenRouter / Groq)",
                              hintStyle: TextStyle(fontSize: 9.5, color: provider.textSecondaryColor),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              prefixIcon: Icon(Icons.bug_report, size: 12, color: provider.neonPinkColor),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: provider.neonCyanColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Show/Hide visibility button
                            IconButton(
                              icon: Icon(
                                _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                                size: 14,
                                color: provider.textSecondaryColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            // Save/Update button
                            SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  provider.updateConfigurations(
                                    owner: provider.githubOwner,
                                    repo: provider.githubRepo,
                                    implementationKey: _implKeyController.text.trim(),
                                    executionKey: _execKeyController.text.trim(),
                                    analysisKey: _analKeyController.text.trim(),
                                  );
                                  setState(() {
                                    _isConfigCollapsed = true;
                                    _showConfigForced = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: provider.neonGreenColor.withOpacity(0.15),
                                  foregroundColor: provider.neonGreenColor,
                                  side: BorderSide(color: provider.neonGreenColor, width: 0.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isConfigured ? "UPDATE KEYS" : "SAVE KEYS",
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (isConfigured) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  icon: Icon(Icons.power_settings_new, color: provider.neonPinkColor, size: 14),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    _implKeyController.clear();
                                    _execKeyController.clear();
                                    _analKeyController.clear();
                                    provider.updateConfigurations(
                                      owner: provider.githubOwner,
                                      repo: provider.githubRepo,
                                      implementationKey: "",
                                      executionKey: "",
                                      analysisKey: "",
                                    );
                                    setState(() {
                                      _isConfigCollapsed = false;
                                      _showConfigForced = false;
                                    });
                                  },
                                  tooltip: "Disconnect API Keys",
                                  style: IconButton.styleFrom(
                                    backgroundColor: provider.neonPinkColor.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: BorderSide(color: provider.neonPinkColor.withOpacity(0.3)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Architect (Groq), Execution (Gemini/OpenRouter), Validator (Gemini/OpenRouter/Groq). Keys are automatically routed.",
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            color: provider.neonGreenColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Architect Model dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ARCHITECT MODEL:",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                color: provider.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.sidebarBgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: provider.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: archModels.any((m) => m["value"] == provider.architectModel)
                                      ? provider.architectModel
                                      : null,
                                  dropdownColor: provider.sidebarBgColor,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: provider.neonCyanColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: provider.neonCyanColor, size: 14),
                                  items: archModels.map((m) {
                                    return DropdownMenuItem<String>(
                                      value: m["value"],
                                      child: Text(m["label"]!),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.updateArchitectModel(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Executioner Model dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "EXECUTIONER MODEL:",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                color: provider.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.sidebarBgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: provider.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: execModels.any((m) => m["value"] == provider.executionerModel)
                                      ? provider.executionerModel
                                      : null,
                                  dropdownColor: provider.sidebarBgColor,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: provider.neonCyanColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: provider.neonCyanColor, size: 14),
                                  items: execModels.map((m) {
                                    return DropdownMenuItem<String>(
                                      value: m["value"],
                                      child: Text(m["label"]!),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.updateExecutionerModel(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Analyzer Model dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ANALYZER MODEL:",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                color: provider.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.sidebarBgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: provider.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: analModels.any((m) => m["value"] == provider.analyzerModel)
                                      ? provider.analyzerModel
                                      : null,
                                  dropdownColor: provider.sidebarBgColor,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: provider.neonCyanColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: provider.neonCyanColor, size: 14),
                                  items: analModels.map((m) {
                                    return DropdownMenuItem<String>(
                                      value: m["value"],
                                      child: Text(m["label"]!),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.updateAnalyzerModel(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "API ENDPOINT VERSION:",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                color: provider.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.sidebarBgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: provider.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: provider.geminiApiVersion,
                                  dropdownColor: provider.sidebarBgColor,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: provider.neonCyanColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: provider.neonCyanColor, size: 14),
                                  items: const [
                                    DropdownMenuItem(value: "v1", child: Text("v1 (Stable)")),
                                    DropdownMenuItem(value: "v1beta", child: Text("v1beta (Preview)")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.updateGeminiApiVersion(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "AGENT LANGUAGE:",
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                color: provider.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.sidebarBgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: provider.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: provider.agentLanguage,
                                  dropdownColor: provider.sidebarBgColor,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: provider.neonCyanColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: provider.neonCyanColor, size: 14),
                                  items: const [
                                    DropdownMenuItem(value: "English", child: Text("English")),
                                    DropdownMenuItem(value: "Marathi (मराठी)", child: Text("मराठी (Marathi)")),
                                    DropdownMenuItem(value: "Hindi (हिन्दी)", child: Text("हिन्दी (Hindi)")),
                                    DropdownMenuItem(value: "Gujarati (ગુજરાતી)", child: Text("ગુજરાતી (Gujarati)")),
                                    DropdownMenuItem(value: "Tamil (தமிழ்)", child: Text("தமிழ் (Tamil)")),
                                    DropdownMenuItem(value: "Telugu (తెలుగు)", child: Text("తెలుగు (Telugu)")),
                                    DropdownMenuItem(value: "Kannada (ಕನ್ನಡ)", child: Text("ಕನ್ನಡ (Kannada)")),
                                    DropdownMenuItem(value: "Bengali (বাংলা)", child: Text("বাংলা (Bengali)")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.setAgentLanguage(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],

        // Chatbox Section (below it)
        Expanded(
          child: isConfigured
              ? _buildChatInterface(provider)
              : _buildLockedInterface(provider),
        ),
      ],
    );
  }

  Widget _buildLockedInterface(IdeProvider provider) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: provider.textSecondaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "AGENT CHAT OFFLINE",
              style: GoogleFonts.outfit(
                color: provider.textSecondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Please enter your Gemini or OpenRouter API Key above to unlock the Agentic Coding Chat. Once activated, you can chat with the agent to write and edit code in your active tabs.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: provider.textSecondaryColor.withOpacity(0.7),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(IdeProvider provider) {
    return Column(
      children: [
        // Chat Header (hidden in full AI mode to prevent double headers)
        if (!provider.fullAiMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: provider.cardBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 12, color: provider.neonPurpleColor),
                        const SizedBox(width: 6),
                        Text(
                          "AGENTIC CODING CHAT",
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: provider.textPrimaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: provider.neonCyanColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: provider.neonCyanColor, width: 0.5),
                          ),
                          child: Text(
                            provider.agentLanguage.split(' ').first.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: provider.neonCyanColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showConfigForced ? Icons.close_fullscreen : Icons.settings,
                    size: 13,
                    color: _showConfigForced ? provider.neonCyanColor : provider.textSecondaryColor,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () {
                    setState(() {
                      _showConfigForced = !_showConfigForced;
                    });
                  },
                  tooltip: _showConfigForced ? "Hide settings panel" : "Show settings panel",
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // Chat Message History
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            physics: const BouncingScrollPhysics(),
            itemCount: provider.agentChatHistory.length,
            itemBuilder: (context, index) {
              final message = provider.agentChatHistory[index];
              final isUser = message["role"] == "user";
              return _AgentChatBubble(
                message: message,
                isUser: isUser,
                provider: provider,
              );
            },
          ),
        ),

        // Typing Loader
        if (provider.isGeneratingAgentCode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: provider.neonPurpleColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.neonPurpleColor.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: provider.neonPurpleColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Agent is writing code...",
                    style: GoogleFonts.outfit(
                      fontSize: 9, 
                      color: provider.neonPurpleColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Message input area with modern premium styling
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: provider.sidebarBgColor,
            border: Border(top: BorderSide(color: provider.borderColor)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: provider.cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: provider.isGeneratingAgentCode 
                    ? provider.neonGreenColor.withOpacity(0.5) 
                    : provider.neonPurpleColor.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: provider.neonPurpleColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: provider.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ask agent to edit/generate...",
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 11,
                        color: provider.textSecondaryColor.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) {
                      final txt = val.trim();
                      if (txt.isNotEmpty && !provider.isGeneratingAgentCode) {
                        provider.sendAgentChatMessage(txt);
                        _chatController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        provider.neonPurpleColor,
                        provider.neonCyanColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: provider.neonPurpleColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      final txt = _chatController.text.trim();
                      if (txt.isNotEmpty && !provider.isGeneratingAgentCode) {
                        provider.sendAgentChatMessage(txt);
                        _chatController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // ==========================================
  // TERMINAL PANEL
  // ==========================================
  Widget _buildTerminal(IdeProvider provider) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int cols = (constraints.maxWidth / 7.5).floor().clamp(10, 200);
                final int rows = (constraints.maxHeight / 14.0).floor().clamp(5, 100);
                
                Future.microtask(() {
                  if (provider.terminal.viewWidth != cols || provider.terminal.viewHeight != rows) {
                    provider.terminal.resize(cols, rows);
                  }
                });

                return TerminalView(
                  provider.terminal,
                  autofocus: false,
                  textStyle: TerminalStyle(
                    fontSize: provider.terminalFontSize,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ),
        // Terminal control buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: provider.sidebarBgColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Termux Emulator Link",
                style: GoogleFonts.outfit(fontSize: 8, color: provider.textSecondaryColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_sweep, size: 14, color: provider.textSecondaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      provider.terminal.write('\x1b[2J\x1b[H');
                      provider.writeToTerminal("[Console] Logs cleared successfully.\r\n");
                    },
                    tooltip: "Clear terminal console",
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: provider.isBuilding ? null : provider.buildApk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.neonGreenColor.withOpacity(0.2),
                      foregroundColor: provider.neonGreenColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("BUILD APK", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  // ==========================================
  // ARTIFACTS PANEL
  // ==========================================
  Widget _buildArtifacts(IdeProvider provider) {
    return provider.artifacts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wallpaper, size: 28, color: provider.textSecondaryColor.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text(
                  "NO ARTIFACTS GENERATED",
                  style: GoogleFonts.outfit(fontSize: 10, color: provider.textSecondaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: provider.artifacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final artifact = provider.artifacts[index];

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: provider.cardBgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: provider.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          artifact.category.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: provider.neonCyanColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${artifact.timestamp.minute}m ago",
                          style: TextStyle(fontSize: 8, color: provider.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artifact.title,
                      style: GoogleFonts.outfit(
                        color: provider.textPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artifact.description,
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 9),
                    ),
                    const SizedBox(height: 8),
                    // Image placeholder simulation to show TV layout representation
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: provider.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 12, color: provider.textSecondaryColor),
                          const SizedBox(width: 6),
                          Text(
                            "Tap to inspect casting screenshot",
                            style: GoogleFonts.outfit(fontSize: 9, color: provider.textSecondaryColor),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
  }
}

class _AgentChatBubble extends StatefulWidget {
  final Map<String, String> message;
  final bool isUser;
  final IdeProvider provider;

  const _AgentChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.provider,
  }) : super(key: key);

  @override
  State<_AgentChatBubble> createState() => _AgentChatBubbleState();
}

class _AgentChatBubbleState extends State<_AgentChatBubble> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final code = widget.message["code"];
    final isUser = widget.isUser;
    final provider = widget.provider;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble label: icon and name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Icon(
                  Icons.psychology, 
                  size: 13, 
                  color: provider.neonPurpleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  "AI ASSISTANT",
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: provider.neonPurpleColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ] else ...[
                Text(
                  "YOU",
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: provider.neonCyanColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.person, 
                  size: 13, 
                  color: provider.neonCyanColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Chat bubble container
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: provider.fullAiMode ? 450 : 260,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          provider.neonCyanColor.withOpacity(0.18),
                          provider.neonPurpleColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          provider.cardBgColor,
                          provider.sidebarBgColor.withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(2),
                  bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isUser 
                      ? provider.neonCyanColor.withOpacity(0.4) 
                      : provider.neonPurpleColor.withOpacity(0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? provider.neonCyanColor : provider.neonPurpleColor)
                        .withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.message["text"] ?? "",
                    style: GoogleFonts.outfit(
                      color: provider.textPrimaryColor,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  if (code != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: provider.borderColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isExpanded 
                                      ? Icons.keyboard_arrow_down 
                                      : Icons.keyboard_arrow_right,
                                  size: 14,
                                  color: provider.neonGreenColor,
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.code_rounded, size: 12, color: provider.neonGreenColor),
                                const SizedBox(width: 6),
                                Text(
                                  _isExpanded ? "HIDE CODE" : "VIEW CODE",
                                  style: GoogleFonts.outfit(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: provider.neonGreenColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Copy code button
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: provider.sidebarBgColor,
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  "Code copied to clipboard!",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: provider.neonGreenColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, size: 11, color: provider.neonCyanColor),
                                const SizedBox(width: 4),
                                Text(
                                  "COPY",
                                  style: GoogleFonts.outfit(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: provider.neonCyanColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: provider.borderColor.withOpacity(0.8), 
                            width: 0.8,
                          ),
                        ),
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: SelectableText(
                                  code,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    color: const Color(0xFFE4E4E7),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
