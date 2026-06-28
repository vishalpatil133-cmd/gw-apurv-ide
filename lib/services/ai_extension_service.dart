import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service to handle AI features like code suggestion, code explanation, and bug fixing.
/// Configurable dynamically via user's own credentials (similar to VS Code account/settings configuration).
class AIExtensionService {
  String? _apiKey;
  String? _customEndpoint;
  GenerativeModel? _model;

  String _modelName = 'gemini-2.5-flash';
  String get modelName => _modelName;

  String _apiVersion = 'v1';
  String get apiVersion => _apiVersion;

  /// Updates the configuration. Re-initializes the AI engine dynamically when the user logs in or updates settings.
  void updateConfig({String? apiKey, String? customEndpoint, String? modelName, String? apiVersion}) {
    _apiKey = apiKey;
    _customEndpoint = customEndpoint;
    if (modelName != null && modelName.trim().isNotEmpty) {
      _modelName = modelName.trim();
    }
    if (apiVersion != null && apiVersion.trim().isNotEmpty) {
      _apiVersion = apiVersion.trim();
    }

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      if (apiKey.trim().startsWith("sk-or-")) {
        _model = null;
        developer.log("AI Extension configured using OpenRouter gateway with model: $_modelName");
      } else {
        // Normalize modelName for standard Google Gemini SDK if it contains OpenRouter paths/suffixes
        String geminiModelName = _modelName;
        if (geminiModelName.contains("/")) {
          geminiModelName = geminiModelName.split("/").last;
        }
        if (geminiModelName.contains(":")) {
          geminiModelName = geminiModelName.split(":").first;
        }
        // Fallback if model is not a Gemini model
        if (!geminiModelName.startsWith("gemini-")) {
          geminiModelName = "gemini-2.5-flash";
        }

        _model = GenerativeModel(
          model: geminiModelName,
          apiKey: apiKey.trim(),
          requestOptions: RequestOptions(apiVersion: _apiVersion),
        );
        developer.log("AI Extension dynamically configured with $geminiModelName (API version $_apiVersion).");
      }
    } else {
      _model = null;
      developer.log("AI Extension configuration cleared.");
    }
  }

  /// Whether the AI extension is active and configured
  bool get isConfigured => _model != null || (_apiKey != null && _apiKey!.trim().startsWith("sk-or-")) || (_customEndpoint != null && _customEndpoint!.isNotEmpty);

  /// Suggests the next code snippet based on current file context and cursor position
  Future<String> suggestCode({
    required String filePath,
    required String fileContent,
    required int cursorPosition,
  }) async {
    if (!isConfigured) {
      return "AI Extension not configured. Please log in or add your API Key in Settings.";
    }

    final prompt = """
You are the Antigravity AI Code Suggestion assistant.
Below is the content of the file '$filePath'. The user's cursor is at character index $cursorPosition (0-indexed).
Predict and suggest the NEXT LINE or block of code to write.
Return ONLY the direct code suggestion. Do NOT wrap it in markdown code fences, do NOT include explanations, and do NOT talk.
If no suggestion is appropriate, return nothing.

File Context:
$fileContent
""";

    try {
      if (_model != null) {
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        return response.text ?? "";
      } else if (_apiKey != null && _apiKey!.trim().startsWith("sk-or-")) {
        return await _queryOpenRouter(_apiKey!, prompt);
      }
      return "";
    } catch (e) {
      developer.log("AI suggestion error: $e");
      return "Error: $e";
    }
  }

  /// Explains a block of code, supporting bilingual English/Marathi explanations
  Future<String> explainCode({
    required String codeSnippet,
    bool inMarathi = false,
  }) async {
    if (!isConfigured) {
      return "AI Extension not configured. Please log in or add your API Key in Settings.";
    }

    final languageInstruction = inMarathi
        ? "मराठी भाषेत (in Marathi language) सोप्या शब्दांत स्पष्टीकरण द्या. हा कोड काय करतो आणि कसा चालतो ते सांगा."
        : "Explain this code block in simple English. Explain its purpose and logic step-by-step.";

    final prompt = """
You are the Antigravity Smart Guru.
$languageInstruction

Code Snippet:
```dart
$codeSnippet
```
""";

    try {
      if (_model != null) {
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        return response.text ?? "No explanation returned.";
      } else if (_apiKey != null && _apiKey!.trim().startsWith("sk-or-")) {
        return await _queryOpenRouter(_apiKey!, prompt);
      }
      return "Endpoint not supported yet.";
    } catch (e) {
      developer.log("AI explanation error: $e");
      return "Error: $e";
    }
  }

  /// Suggests code modifications to resolve errors and explains the bug
  Future<String> fixBugs({
    required String buggyCode,
    required String errorMessage,
  }) async {
    if (!isConfigured) {
      return "AI Extension not configured. Please log in or add your API Key in Settings.";
    }

    final prompt = """
You are the Antigravity Bug Fixer.
Identify the bugs in the following code block and provide a fixed version, along with a brief, clear explanation of the errors.

Buggy Code:
```dart
$buggyCode
```

Error Message/Log:
$errorMessage
""";

    try {
      if (_model != null) {
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        return response.text ?? "No bug fix response returned.";
      } else if (_apiKey != null && _apiKey!.trim().startsWith("sk-or-")) {
        return await _queryOpenRouter(_apiKey!, prompt);
      }
      return "Endpoint not supported yet.";
    } catch (e) {
      developer.log("AI bug fixer error: $e");
      return "Error: $e";
    }
  }

  /// Sends a raw prompt to the model and returns the text response
  Future<String> getAgentResponse(String prompt) async {
    if (!isConfigured) {
      return "AI Extension not configured.";
    }
    try {
      if (_model != null) {
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        return response.text ?? "";
      } else if (_apiKey != null && _apiKey!.trim().startsWith("sk-or-")) {
        return await _queryOpenRouter(_apiKey!, prompt);
      }
      return "Generative model is not initialized.";
    } catch (e) {
      developer.log("AI Agent error: $e");
      return "Error: $e";
    }
  }

  /// Auto-detects the provider (gemini, openrouter, or groq) based on the key prefix
  String detectProvider(String key) {
    final clean = key.trim();
    if (clean.startsWith("gsk_")) return "groq";
    if (clean.startsWith("sk-or-")) return "openrouter";
    return "gemini";
  }

  /// Sends a prompt to the specified provider (groq, openrouter, or gemini) using its API key
  Future<String> queryProvider({
    required String apiKey,
    required String provider, // 'groq', 'openrouter', 'gemini'
    required String model,
    required String prompt,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return "Error: API Key is empty.";
    }

    try {
      if (provider.toLowerCase() == 'gemini') {
        String geminiModelName = model.trim();
        if (geminiModelName.contains("/")) {
          geminiModelName = geminiModelName.split("/").last;
        }
        if (geminiModelName.contains(":")) {
          geminiModelName = geminiModelName.split(":").first;
        }
        if (!geminiModelName.startsWith("gemini-")) {
          geminiModelName = "gemini-2.5-flash";
        }

        final tempModel = GenerativeModel(
          model: geminiModelName,
          apiKey: cleanKey,
          requestOptions: RequestOptions(apiVersion: _apiVersion),
        );
        final content = [Content.text(prompt)];
        final response = await tempModel.generateContent(content);
        return response.text ?? "";
      } else if (provider.toLowerCase() == 'openrouter') {
        final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");
        String modelSlug = model.trim();
        if (modelSlug == 'gemini-2.5-flash') {
          modelSlug = "google/gemini-2.5-flash";
        } else if (modelSlug == 'gemini-2.5-pro') {
          modelSlug = "google/gemini-2.5-pro";
        } else if (modelSlug == 'gemini-2.0-flash') {
          modelSlug = "google/gemini-2.0-flash";
        } else if (modelSlug == 'gemini-1.5-flash') {
          modelSlug = "google/gemini-1.5-flash";
        } else if (modelSlug == 'gemini-1.5-pro') {
          modelSlug = "google/gemini-1.5-pro";
        }

        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $cleanKey",
            "HTTP-Referer": "https://gwide.workspace.local",
            "X-Title": "GW MOBILE IDE",
          },
          body: json.encode({
            "model": modelSlug,
            "messages": [
              {"role": "user", "content": prompt}
            ]
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["choices"][0]["message"]["content"] ?? "";
        } else {
          return "Error OpenRouter (${response.statusCode}): ${response.body}";
        }
      } else if (provider.toLowerCase() == 'groq') {
        final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");
        String modelSlug = model.trim();
        if (modelSlug.contains("gemini") || modelSlug.isEmpty) {
          modelSlug = "llama-3.3-70b-versatile";
        }
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $cleanKey",
          },
          body: json.encode({
            "model": modelSlug,
            "messages": [
              {"role": "user", "content": prompt}
            ]
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["choices"][0]["message"]["content"] ?? "";
        } else {
          return "Error Groq (${response.statusCode}): ${response.body}";
        }
      }
      return "Error: Unsupported provider '$provider'.";
    } catch (e) {
      return "Error queryProvider: $e";
    }
  }

  /// Helper to send requests directly to OpenRouter API
  Future<String> _queryOpenRouter(String key, String prompt) async {
    try {
      final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");
      // Map model names to OpenRouter compatible model format if needed
      String modelSlug = _modelName;
      if (modelSlug == 'gemini-2.5-flash') {
        modelSlug = "google/gemini-2.5-flash";
      } else if (modelSlug == 'gemini-2.5-pro') {
        modelSlug = "google/gemini-2.5-pro";
      } else if (modelSlug == 'gemini-2.0-flash') {
        modelSlug = "google/gemini-2.0-flash";
      } else if (modelSlug == 'gemini-1.5-flash') {
        modelSlug = "google/gemini-1.5-flash";
      } else if (modelSlug == 'gemini-1.5-pro') {
        modelSlug = "google/gemini-1.5-pro";
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${key.trim()}",
          "HTTP-Referer": "https://gwide.workspace.local",
          "X-Title": "GW MOBILE IDE",
        },
        body: json.encode({
          "model": modelSlug,
          "messages": [
            {"role": "user", "content": prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["choices"][0]["message"]["content"] ?? "";
      } else {
        return "Error OpenRouter (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "OpenRouter connection error: $e";
    }
  }
}
