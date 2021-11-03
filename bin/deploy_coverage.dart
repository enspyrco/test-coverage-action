import 'dart:io';

import 'package:deploy_coverage/firebase_hosting_api.dart';
import 'package:deploy_coverage/models/repo_config.dart';
import 'package:deploy_coverage/models/upload_data.dart';

/// The CWD of the app is assumed to be $GITHUB_WORKSPACE
/// This is true when run with the current entrypoint.sh
void main(List<String> arguments) async {
  var repo = RepoConfig.detect();

  var key = Platform.environment['INPUT_SERVICE_ACCOUNT_KEY'] ?? '';
  if (key.isEmpty) throw 'key not found, check service_account_key input';
  // var key = File('key.json').readAsStringSync();

  var api = await FirebaseHostingApi.create(key: key);

  final uploadData = await UploadData.createFrom(dirPath: repo.dirPath);

  var currentVersion = await api.getCurrentVersion();

  // Allow coverage data for different packages to be uploaded at different
  // times without overwriting everything.
  if (repo.isMultiPackage) {
    var currentFiles = await api.listFiles(versionName: currentVersion);

    // Add current file paths and hashes to upload data, if not from package.
    for (var file in currentFiles) {
      var firstSegment = file.path.split('/').elementAt(1);

      if (firstSegment != repo.dirPath && firstSegment != '__') {
        uploadData.json[file.path] = file.hash;
      }
    }
  }

  var newVersion = await api.createNewVersion();

  var requiredHashes = await api.populateFiles(
    uploadData: uploadData,
    versionName: newVersion,
  );

  await api.uploadFiles(requiredHashes: requiredHashes, uploadData: uploadData);

  await api.finalizeStatus(versionName: newVersion);
  await api.release(versionName: newVersion);

  api.closeClient();
}
