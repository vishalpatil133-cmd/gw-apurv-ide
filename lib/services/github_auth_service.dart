import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// ... Class definitions and helper functions remain unchanged ...


/// Model class representing the authenticated GitHub user profile
class GithubUser {
  final String login;
  final int id;
  final String avatarUrl;
  final String name;
  final String profileUrl;
  final int publicRepos;
  final String token;

  GithubUser({
    required this.login,
    required this.id,
    required this.avatarUrl,
    required this.name,
    required this.profileUrl,
    required this.publicRepos,
    required this.token,
  });

  factory GithubUser.fromJson(Map<String, dynamic> json, String token) {
    return GithubUser(
      login: json['login'] ?? 'unknown',
      id: json['id'] ?? 0,
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? json['login'] ?? 'GitHub Developer',
      profileUrl: json['html_url'] ?? '',
      publicRepos: json['public_repos'] ?? 0,
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'id': id,
      'avatar_url': avatarUrl,
      'name': name,
      'html_url': profileUrl,
      'public_repos': publicRepos,
      'token': token,
    };
  }
}

/// Service to manage user authentication and token checks with GitHub API.
class GithubAuthService {
  /// Validates a PAT and fetches user profile details from the GitHub User API.
  /// Throws Exception on network failure or invalid credentials.
  Future<GithubUser> authenticateWithToken(String token) async {
    final url = Uri.parse('https://api.github.com/user');
    
    developer.log("Verifying GitHub token via /user API...");
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      developer.log("GitHub token validated successfully for @${data['login']}.");
      return GithubUser.fromJson(data, token);
    } else {
      developer.log("Failed to validate GitHub token. Status: ${response.statusCode}, Body: ${response.body}");
      throw Exception("Invalid token (Code ${response.statusCode}): ${response.reasonPhrase}");
    }
  }

  /// Exchanges the OAuth authorization code for an access token.
  Future<String> exchangeCodeForToken({
    required String clientId,
    required String clientSecret,
    required String code,
    required String redirectUri,
  }) async {
    final url = Uri.parse('https://github.com/login/oauth/access_token');

    developer.log("Exchanging OAuth code for token...");
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'] as String?;
      if (token != null) {
        return token;
      }
      throw Exception("GitHub response missing access_token: ${response.body}");
    } else {
      developer.log("Failed to exchange code. Status: ${response.statusCode}, Body: ${response.body}");
      throw Exception("OAuth code exchange failed (Code ${response.statusCode})");
    }
  }

  /// Simulates OAuth web authorization and returns a mock user credentials payload.
  Future<GithubUser> simulateOAuthLogin() async {
    if (kReleaseMode) {
      throw Exception("Fatal: Simulated OAuth login is disabled in Production Release Mode.");
    }
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate redirect/web verification delay
    return GithubUser(
      login: "antigravity-dev",
      id: 991283,
      avatarUrl: "https://avatars.githubusercontent.com/u/991283?v=4", // standard profile placeholder
      name: "Antigravity Cast User",
      profileUrl: "https://github.com/antigravity-dev",
      publicRepos: 18,
      token: "ghp_mockTokenSequenceForCastingAppDemo",
    );
  }

  /// Checks if the specified repository exists
  Future<bool> checkRepositoryExists(String token, String owner, String repo) async {
    if (token.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true; // Mock exist check success
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    return response.statusCode == 200;
  }

  /// Creates a private repository for the user
  Future<void> createPrivateRepository(String token, String repo) async {
    if (token.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    final url = Uri.parse('https://api.github.com/user/repos');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': repo,
        'private': true,
        'description': 'User-owned workspace for GW IDE cloud compilation',
        'auto_init': true,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception("Failed to create repository: ${response.statusCode} - ${response.body}");
    }
  }

  /// Retrieves the file SHA of a path if it exists, otherwise null
  Future<String?> getFileSha(String token, String owner, String repo, String path) async {
    if (token.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 300));
      return null; // Not found in mock
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sha'] as String?;
    }
    return null;
  }

  /// Commits a file (or updates it if SHA is provided) using GitHub Contents API
  Future<bool> commitWorkflowFile(String token, String owner, String repo, String path, String content, String? sha) async {
    if (token.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final base64Content = base64Encode(utf8.encode(content));
    final bodyMap = {
      'message': 'Configure Flutter Actions build workflow',
      'content': base64Content,
    };
    if (sha != null) {
      bodyMap['sha'] = sha;
    }

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyMap),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Firebase Auth चा वापर करून GitHub लॉगिन फ्लो सुरू करतो.
  /// यशस्वी लॉगिन झाल्यावर [UserCredential] रिटर्न करतो.
  Future<UserCredential?> signInWithGitHub() async {
    try {
      final GithubAuthProvider gitHubProvider = GithubAuthProvider();
      
      // स्कोप्स ॲड करण्यासाठी (उदा. repo ॲक्सेस)
      gitHubProvider.addScope('repo');
      gitHubProvider.addScope('workflow');

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithProvider(gitHubProvider);

      final User? user = userCredential.user;
      if (user != null) {
        developer.log("[Firebase GitHub Auth] लॉगिन यशस्वी! युजर: ${user.displayName}");
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log("[Firebase GitHub Auth] Error: [${e.code}] - ${e.message}");
      rethrow;
    } catch (e) {
      developer.log("[Firebase GitHub Auth] Unexpected error: $e");
      return null;
    }
  }
}
