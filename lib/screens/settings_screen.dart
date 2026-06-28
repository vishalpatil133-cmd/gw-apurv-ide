import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ide_provider.dart';
import '../theme/app_theme.dart';
import 'overlays/github_login_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _implController = TextEditingController();
  final TextEditingController _execController = TextEditingController();
  final TextEditingController _analController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<IdeProvider>(context, listen: false);
    
    _ownerController.text = provider.githubOwner;
    _repoController.text = provider.githubRepo;
    _implController.text = provider.implementationApiKey;
    _execController.text = provider.executionApiKey;
    _analController.text = provider.analysisApiKey;
    _customModelController.text = provider.geminiModel;

    _execController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _implController.dispose();
    _execController.dispose();
    _analController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = Provider.of<IdeProvider>(context, listen: false);
    
    provider.updateConfigurations(
      owner: _ownerController.text,
      repo: _repoController.text,
      implementationKey: _implController.text,
      executionKey: _execController.text,
      analysisKey: _analController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Configurations saved successfully!"),
        backgroundColor: AppColors.neonGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  void _openOAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const GithubLoginDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    List<Map<String, String>> getModelsForKey(String key) {
      final k = key.trim();
      if (k.startsWith("gsk_")) {
        return [
          {"value": "llama-3.3-70b-versatile", "label": "Llama 3.3 70B (Groq)"},
          {"value": "llama3-70b-8192", "label": "Llama 3 70B (Groq)"},
          {"value": "mixtral-8x7b-32768", "label": "Mixtral 8x7B (Groq)"},
          {"value": "gemma2-9b-it", "label": "Gemma 2 9B (Groq)"},
        ];
      } else if (k.startsWith("sk-")) {
        return [
          {"value": "google/gemini-2.5-flash:free", "label": "Gemini 2.5 (Free)"},
          {"value": "nvidia/nemotron-3-super-120b-a12b:free", "label": "Nemotron 3 (Free)"},
          {"value": "meta-llama/llama-3.3-70b-instruct:free", "label": "Llama 3.3 70B (Free)"},
          {"value": "deepseek/deepseek-chat:free", "label": "DeepSeek Chat (Free)"},
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
          {"value": "meta-llama/llama-3.3-70b-instruct:free", "label": "Llama 3.3 70B (Free)"},
          {"value": "deepseek/deepseek-chat:free", "label": "DeepSeek Chat (Free)"},
          {"value": "qwen/qwen-2.5-coder-32b-instruct:free", "label": "Qwen 2.5 Coder (Free)"},
          {"value": "llama-3.3-70b-versatile", "label": "Llama 3.3 70B (Groq)"},
        ];
      }
    }

    final archModels = getModelsForKey(_implController.text);
    final execModels = getModelsForKey(_execController.text);
    final analModels = getModelsForKey(_analController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("GW APURV IDE CONFIGURATIONS"),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, color: AppColors.neonGreen),
            tooltip: "Save Configuration",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // GITHUB ACCOUNTS / PROFILE PANEL
            // ==========================================
            _buildSectionHeader("GitHub Account", Icons.account_circle),
            const SizedBox(height: 12),
            _buildCard(
              child: provider.isLoggedIn
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(provider.currentUser!.avatarUrl),
                          backgroundColor: AppColors.border,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.currentUser!.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                "@${provider.currentUser!.login}",
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.neonCyan,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Quota Type: Free Developer Plan (2,000 mins)",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              )
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: provider.logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.neonPink,
                            side: const BorderSide(color: AppColors.neonPink),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text("SIGN OUT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Authenticate using official browser redirection or Personal Access Token (PAT).",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: provider.isLoggingIn ? null : provider.loginWithOAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          icon: provider.isLoggingIn
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(Icons.hub, color: Colors.black, size: 18),
                          label: Text(
                            provider.isLoggingIn ? "AUTHENTICATING..." : "SIGN IN WITH GITHUB",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: provider.isLoggingIn ? null : _openOAuthDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.vpn_key, color: AppColors.neonCyan, size: 16),
                          label: Text(
                            "SIGN IN WITH PERSONAL ACCESS TOKEN (PAT)",
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // APPEARANCE / THEME SETTINGS
            // ==========================================
            _buildSectionHeader("Appearance & Theme", Icons.palette_outlined),
            const SizedBox(height: 12),
            _buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.lightThemeActive
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: AppColors.neonCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.lightThemeActive ? "Light Theme" : "Dark Theme",
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.lightThemeActive
                            ? "Switch to dark mode for lower eye strain in low light."
                            : "Switch to light mode for better visibility in bright environments.",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                  Switch(
                    value: provider.lightThemeActive,
                    onChanged: (val) => provider.setLightThemeActive(val),
                    activeColor: AppColors.neonCyan,
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.border,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("GitHub Compiler Target Settings", Icons.cloud_queue),
            const SizedBox(height: 4),
            Text(
              "Compiles code from user profile repositories when logged in.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 8),
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: "Compilation Owner (bypassed if logged in)",
                      prefixIcon: Icon(Icons.person, color: AppColors.neonCyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _repoController,
                    decoration: const InputDecoration(
                      labelText: "Compilation Repository",
                      prefixIcon: Icon(Icons.folder_shared, color: AppColors.neonCyan),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

             _buildSectionHeader("GW Smart AI Extension", Icons.psychology),
             const SizedBox(height: 12),
             _buildCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     "Input your three separate AI keys to configure the agent pipeline.",
                     style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                   ),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _implController,
                     obscureText: true,
                     decoration: const InputDecoration(
                       labelText: "Implementation Key (Groq)",
                       prefixIcon: Icon(Icons.psychology, color: AppColors.neonPurple),
                     ),
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _execController,
                     obscureText: true,
                     decoration: const InputDecoration(
                       labelText: "Execution Key (Gemini/OpenRouter)",
                       prefixIcon: Icon(Icons.play_arrow, color: AppColors.neonGreen),
                     ),
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _analController,
                     obscureText: true,
                     decoration: const InputDecoration(
                       labelText: "Analysis / Terminal Key",
                       prefixIcon: Icon(Icons.bug_report, color: AppColors.neonPink),
                     ),
                   ),
                   const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Architect Model (Groq)",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: archModels.any((m) => m["value"] == provider.architectModel)
                                  ? provider.architectModel
                                  : null,
                              hint: Text(
                                provider.architectModel.split('/').last,
                                style: const TextStyle(color: AppColors.neonCyan, fontSize: 11),
                              ),
                              dropdownColor: AppColors.cardBg,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonCyan, size: 18),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Executioner Model (Gemini)",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: execModels.any((m) => m["value"] == provider.executionerModel)
                                  ? provider.executionerModel
                                  : null,
                              hint: Text(
                                provider.executionerModel.split('/').last,
                                style: const TextStyle(color: AppColors.neonCyan, fontSize: 11),
                              ),
                              dropdownColor: AppColors.cardBg,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonCyan, size: 18),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Analyzer Model (Terminal)",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: analModels.any((m) => m["value"] == provider.analyzerModel)
                                  ? provider.analyzerModel
                                  : null,
                              hint: Text(
                                provider.analyzerModel.split('/').last,
                                style: const TextStyle(color: AppColors.neonCyan, fontSize: 11),
                              ),
                              dropdownColor: AppColors.cardBg,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonCyan, size: 18),
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
                    const SizedBox(height: 12),
                   const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         "API Endpoint Version",
                         style: GoogleFonts.outfit(
                           fontSize: 11,
                           color: AppColors.textPrimary,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       Container(
                         height: 36,
                         padding: const EdgeInsets.symmetric(horizontal: 12),
                         decoration: BoxDecoration(
                           color: AppColors.background,
                           borderRadius: BorderRadius.circular(6),
                           border: Border.all(color: AppColors.border),
                         ),
                         child: DropdownButtonHideUnderline(
                           child: DropdownButton<String>(
                             value: provider.geminiApiVersion,
                             dropdownColor: AppColors.cardBg,
                             style: GoogleFonts.jetBrainsMono(
                               color: AppColors.neonCyan,
                               fontSize: 11,
                               fontWeight: FontWeight.bold,
                             ),
                             icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonCyan, size: 18),
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
                 ],
               ),
              ),
             const SizedBox(height: 24),

             _buildSectionHeader("Offline Local AI (LiteML)", Icons.wifi_off),
             const SizedBox(height: 12),
             _buildCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               "Use Offline API (LiteML)",
                               style: GoogleFonts.outfit(
                                 color: AppColors.textPrimary,
                                 fontSize: 13,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               "Runs AI models locally without internet connection.",
                               style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                             ),
                           ],
                         ),
                       ),
                       Switch(
                         value: provider.useOfflineApi,
                         onChanged: (val) => provider.setUseOfflineApi(val),
                         activeColor: AppColors.neonGreen,
                         inactiveThumbColor: AppColors.textSecondary,
                         inactiveTrackColor: AppColors.border,
                       ),
                     ],
                   ),
                   if (provider.useOfflineApi) ...[
                     const SizedBox(height: 16),
                     Divider(color: AppColors.border, height: 1),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           "Select Local Model",
                           style: GoogleFonts.outfit(
                             fontSize: 11,
                             color: AppColors.textPrimary,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         Container(
                           height: 36,
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           decoration: BoxDecoration(
                             color: AppColors.background,
                             borderRadius: BorderRadius.circular(6),
                             border: Border.all(color: AppColors.border),
                           ),
                           child: DropdownButtonHideUnderline(
                             child: DropdownButton<String>(
                               value: provider.downloadedOfflineModels.contains(provider.selectedOfflineModel)
                                   ? provider.selectedOfflineModel
                                   : (provider.downloadedOfflineModels.isNotEmpty ? provider.downloadedOfflineModels.first : null),
                               hint: const Text(
                                 "No Model Downloaded",
                                 style: TextStyle(color: AppColors.neonPink, fontSize: 11),
                               ),
                               dropdownColor: AppColors.cardBg,
                               style: GoogleFonts.jetBrainsMono(
                                 color: AppColors.neonCyan,
                                 fontSize: 11,
                                 fontWeight: FontWeight.bold,
                               ),
                               icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonCyan, size: 18),
                               items: provider.downloadedOfflineModels.map((m) {
                                 return DropdownMenuItem<String>(
                                   value: m,
                                   child: Text(m),
                                 );
                               }).toList(),
                               onChanged: (val) {
                                 if (val != null) {
                                   provider.setSelectedOfflineModel(val);
                                 }
                               },
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                     Text(
                       "Available LiteML Models",
                       style: GoogleFonts.outfit(
                         fontSize: 11,
                         color: AppColors.textPrimary,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 8),
                     ...["Gemma 2B (LiteML)", "Phi-2 (LiteML)", "TinyLlama 1.1B (LiteML)"].map((modelName) {
                       final isDownloaded = provider.downloadedOfflineModels.contains(modelName);
                       final isDownloading = provider.offlineDownloadProgress.containsKey(modelName);
                       final progress = provider.offlineDownloadProgress[modelName] ?? 0.0;

                       return Container(
                         margin: const EdgeInsets.symmetric(vertical: 6),
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: AppColors.background,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: AppColors.border, width: 0.5),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       modelName,
                                       style: GoogleFonts.jetBrainsMono(
                                         color: AppColors.textPrimary,
                                         fontSize: 11,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     Text(
                                       modelName.contains("Gemma")
                                           ? "Size: 1.3 GB  •  Google"
                                           : modelName.contains("Phi")
                                               ? "Size: 1.6 GB  •  Microsoft"
                                               : "Size: 680 MB  •  Community",
                                       style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                                     ),
                                   ],
                                 ),
                                 if (isDownloaded) ...[
                                   Row(
                                     children: [
                                       const Icon(Icons.check_circle_outline, color: AppColors.neonGreen, size: 14),
                                       const SizedBox(width: 8),
                                       ElevatedButton(
                                         onPressed: () => provider.deleteOfflineModel(modelName),
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: Colors.transparent,
                                           foregroundColor: AppColors.neonPink,
                                           side: const BorderSide(color: AppColors.neonPink, width: 0.5),
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                           minimumSize: Size.zero,
                                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                         ),
                                         child: const Text("DELETE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                       ),
                                     ],
                                   )
                                 ] else if (isDownloading) ...[
                                   SizedBox(
                                     width: 14,
                                     height: 14,
                                     child: CircularProgressIndicator(
                                       value: progress,
                                       color: AppColors.neonGreen,
                                       strokeWidth: 1.5,
                                     ),
                                   )
                                 ] else ...[
                                   ElevatedButton(
                                     onPressed: () => provider.downloadOfflineModel(modelName),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppColors.neonGreen.withOpacity(0.1),
                                       foregroundColor: AppColors.neonGreen,
                                       side: const BorderSide(color: AppColors.neonGreen, width: 0.5),
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                       minimumSize: Size.zero,
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                     ),
                                     child: const Text("DOWNLOAD", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                   )
                                 ],
                               ],
                             ),
                             if (isDownloading) ...[
                               const SizedBox(height: 6),
                               ClipRRect(
                                 borderRadius: BorderRadius.circular(2),
                                 child: LinearProgressIndicator(
                                   value: progress,
                                   minHeight: 3,
                                   backgroundColor: AppColors.border,
                                   valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
                                 ),
                               ),
                             ]
                           ],
                         ),
                       );
                     }).toList(),
                   ],
                 ],
               ),
             ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
