import 'package:deploy_coverage/models/repo_config.dart';
import 'package:deploy_coverage/utils/locator.dart';
import 'package:firebase_hosting_api_client/client.dart';

/// The CWD of the app is assumed to be $GITHUB_WORKSPACE
/// This is true when run with the current entrypoint.sh
void main(List<String> arguments) async {
  final workspaceDir = Locator.getEnvVar('GITHUB_WORKSPACE');
  final key = Locator.getEnvVar('INPUT_SERVICE_ACCOUNT_KEY');
  if (key.isEmpty) throw 'key not found, check service_account_key input';

  var repo = RepoConfig.detect();
  final uploadData = await UploadData.createFrom(
      path: workspaceDir + '/' + repo.dirPath + 'coverage');

  var client = await FirebaseHostingApiClient.create(
      serviceAccountKey: key, projectId: repo.projectId);

  // Allow coverage data for different packages to be uploaded at different
  // times without overwriting everything.

  // var currentVersion = await client.getCurrentVersion();

  // if (repo.isMultiPackage) {
  //   var currentFiles = await client.listFiles(versionName: currentVersion);

  //   // Add current file paths and hashes to upload data, if not from package.
  //   for (var file in currentFiles) {
  //     var firstSegment = file.path.split('/').elementAt(1);

  //     if (firstSegment != repo.dirPath && firstSegment != '__') {
  //       uploadData.json[file.path] = file.hash;
  //     }
  //   }
  // }

  var newVersion = await client.createNewVersion();

  var requiredHashes = await client.populateFiles(
    json: uploadData.json,
    versionName: newVersion,
  );

  await client.uploadFiles(
    requiredHashes: requiredHashes,
    pathForHash: uploadData.pathForHash,
    bytesForHash: uploadData.bytesForHash,
  );

  await client.finalizeStatus(versionName: newVersion);
  await client.release(versionName: newVersion);

  client.close();
}
