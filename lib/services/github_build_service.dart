import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Service to handle remote compilation tasks using GitHub Actions and Repository Dispatches.
/// Exclusively accepts and uses a dynamic, session-based accessToken fetched from the logged-in user.
class GithubBuildService {
  GithubBuildService();

  /// Helper to send an authenticated HTTP request using the provided access token
  Future<http.Response> _sendRequest(
    String token,
    Future<http.Response> Function(String token) requestFn,
  ) async {
    try {
      final response = await requestFn(token);
      if (response.statusCode == 401) {
        throw Exception("GitHub session expired or token is invalid. Please sign in again.");
      }
      return response;
    } catch (e) {
      developer.log("Exception during GitHub API call: $e");
      rethrow;
    }
  }

  /// Triggers a repository dispatch event in the specified compilation repository
  Future<bool> triggerRepositoryDispatch({
    required String owner,
    required String repo,
    required String eventType,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    if (accessToken.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 500));
      developer.log("Mock repository dispatch '$eventType' triggered.");
      return true;
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/dispatches');

    final response = await _sendRequest(accessToken, (token) async {
      return await http.post(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'event_type': eventType,
          'client_payload': payload,
        }),
      );
    });

    if (response.statusCode == 204) {
      developer.log("Repository dispatch '$eventType' triggered successfully.");
      return true;
    } else {
      developer.log("Failed to trigger dispatch. Status: ${response.statusCode}, Body: ${response.body}");
      return false;
    }
  }

  /// Fetches the latest workflow runs to discover the run ID triggered by our dispatch
  Future<Map<String, dynamic>?> findLatestDispatchRun({
    required String owner,
    required String repo,
    String event = 'repository_dispatch',
    required String accessToken,
  }) async {
    if (accessToken.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'id': 123456,
        'run_number': 42,
        'status': 'in_progress',
      };
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/runs?event=$event&per_page=5');

    final response = await _sendRequest(accessToken, (token) async {
      return await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List runs = data['workflow_runs'] ?? [];
      if (runs.isNotEmpty) {
        return runs.first as Map<String, dynamic>;
      }
    }
    return null;
  }

  /// Gets the detailed status of a workflow run by ID
  Future<Map<String, dynamic>?> getWorkflowRunStatus({
    required String owner,
    required String repo,
    required int runId,
    required String accessToken,
  }) async {
    if (accessToken.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'id': runId,
        'status': 'completed',
        'conclusion': 'success',
      };
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/runs/$runId');

    final response = await _sendRequest(accessToken, (token) async {
      return await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Retrieves the list of jobs and steps for a specific workflow run to stream compile progress
  Future<List<Map<String, dynamic>>> getWorkflowRunJobs({
    required String owner,
    required String repo,
    required int runId,
    required String accessToken,
  }) async {
    if (accessToken.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {
          'id': 78910,
          'name': 'build',
          'status': 'in_progress',
        }
      ];
    }
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/runs/$runId/jobs');

    final response = await _sendRequest(accessToken, (token) async {
      return await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List jobs = data['jobs'] ?? [];
      return jobs.map((j) => j as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Fetches the raw text logs for a specific job run.
  /// Endpoint: GET /repos/{owner}/{repo}/actions/jobs/{job_id}/logs
  Future<String?> getWorkflowRunJobLogs({
    required String owner,
    required String repo,
    required int jobId,
    required String accessToken,
  }) async {
    if (accessToken.startsWith("ghp_mock")) {
      await Future.delayed(const Duration(milliseconds: 300));
      return "Mock compilation output segment...\r\n[INFO] Running gradle build...\r\n[SUCCESS] APK compiled successfully under your GitHub session context!";
    }
    
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/jobs/$jobId/logs');

    final response = await _sendRequest(accessToken, (token) async {
      return await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      developer.log("Failed to fetch logs. Status: ${response.statusCode}, Body: ${response.body}");
      return null;
    }
  }
}
