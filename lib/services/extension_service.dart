import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/marketplace_extension.dart';

class ExtensionService {
  static const String remoteJsonUrl = "https://raw.githubusercontent.com/ApurvGW/gw_ide_extensions/main/extensions.json";

  Future<List<MarketplaceExtension>> fetchExtensions() async {
    try {
      final response = await http.get(Uri.parse(remoteJsonUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonItem) => MarketplaceExtension.fromJson(jsonItem)).toList();
      }
    } catch (e) {
      // Fallback to local asset if remote fails
      print("Remote extension fetch failed, falling back to local asset: $e");
    }

    try {
      final String localData = await rootBundle.loadString("assets/extensions.json");
      final List<dynamic> data = json.decode(localData);
      return data.map((jsonItem) => MarketplaceExtension.fromJson(jsonItem)).toList();
    } catch (e) {
      print("Local extension load failed: $e");
      return _getHardcodedFallbackExtensions();
    }
  }

  List<MarketplaceExtension> _getHardcodedFallbackExtensions() {
    return [
      MarketplaceExtension(
        id: "dracula_theme",
        name: "Dracula Official Theme",
        description: "A dark theme for many editors, shells, and more.",
        version: "v2.2.0",
        publisher: "Dracula Team",
        rating: 4.9,
        downloads: 23100,
        iconUrl: "assets/icons/dracula.png",
        type: "theme",
      ),
      MarketplaceExtension(
        id: "python_support",
        name: "Python Language Support",
        description: "Rich support for the Python language including refactoring.",
        version: "v2026.2.0",
        publisher: "Microsoft",
        rating: 4.8,
        downloads: 98400,
        iconUrl: "assets/icons/python.png",
        type: "language",
      ),
      MarketplaceExtension(
        id: "flutter_snippets",
        name: "Flutter Snippets Pro",
        description: "Common Flutter/Dart code snippets for high speed development.",
        version: "v3.1.2",
        publisher: "Flutter Devs",
        rating: 4.7,
        downloads: 14200,
        iconUrl: "assets/icons/flutter.png",
        type: "tool",
      ),
      MarketplaceExtension(
        id: "github_copilot",
        name: "GitHub Copilot Sim",
        description: "AI-assisted completions tuned for offline Cast screens.",
        version: "v1.0.4",
        publisher: "Antigravity AI",
        rating: 4.9,
        downloads: 8500,
        iconUrl: "assets/icons/copilot.png",
        type: "tool",
      ),
      MarketplaceExtension(
        id: "cline_agent",
        name: "Cline Official AI Agent",
        description: "Autonomous AI agent to write code, create files, and execute CLI commands.",
        version: "v3.0.1",
        publisher: "Cline Team",
        rating: 4.9,
        downloads: 54200,
        iconUrl: "assets/icons/cline.png",
        type: "tool",
      ),
    ];
  }
}
