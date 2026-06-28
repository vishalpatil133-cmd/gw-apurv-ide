import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_ide/services/github_auth_service.dart';

void main() {
  group('GithubAuthService & User Model Tests', () {
    test('JSON Parsing verification', () {
      final json = {
        'login': 'octocat',
        'id': 1,
        'avatar_url': 'https://github.com/images/error/octocat_happy.gif',
        'name': 'The Octocat',
        'html_url': 'https://github.com/octocat',
        'public_repos': 8,
      };
      
      final user = GithubUser.fromJson(json, 'mock_access_token');

      expect(user.login, 'octocat');
      expect(user.id, 1);
      expect(user.avatarUrl, 'https://github.com/images/error/octocat_happy.gif');
      expect(user.name, 'The Octocat');
      expect(user.profileUrl, 'https://github.com/octocat');
      expect(user.publicRepos, 8);
      expect(user.token, 'mock_access_token');
    });

    test('Simulated OAuth Login verification', () async {
      final service = GithubAuthService();
      final user = await service.simulateOAuthLogin();

      expect(user.login, 'antigravity-dev');
      expect(user.id, 991283);
      expect(user.token.startsWith('ghp_'), isTrue);
    });

    test('Mock repository setup services verification', () async {
      final service = GithubAuthService();
      const mockToken = 'ghp_mockTokenSequenceForCastingAppDemo';

      final exists = await service.checkRepositoryExists(mockToken, 'owner', 'repo');
      expect(exists, isTrue);

      final sha = await service.getFileSha(mockToken, 'owner', 'repo', 'path');
      expect(sha, isNull);

      final committed = await service.commitWorkflowFile(mockToken, 'owner', 'repo', 'path', 'content', null);
      expect(committed, isTrue);

      // Verify createPrivateRepository does not throw
      expect(service.createPrivateRepository(mockToken, 'repo'), completes);
    });
  });
}
