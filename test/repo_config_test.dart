import 'package:deploy_coverage/models/repo_config.dart';
import 'package:deploy_coverage/utils/locator.dart';
import 'package:test/test.dart';

void main() {
  group('RepoConfig', () {
    /// Env Vars are set using the Locator as RepoConfig uses the Locator to
    /// retrieve them.
    test('.createFrom() generates correct paths', () {
      Locator.setEnvVar('INPUT_PACKAGES_PATH', 'packages');
      Locator.setEnvVar('INPUT_PACKAGE_NAME', 'redfire');
      Locator.setEnvVar('INPUT_PROJECT_ID', 'enspyrco');

      var repo = RepoConfig.detect();
      expect(repo.isMultiPackage, true);
      expect(repo.dirPath, 'packages/redfire/');

      expect(repo.projectId, 'enspyrco');

      // TODO: test reading in .firebaserc ie. when no env var is present
    });
  });
}
