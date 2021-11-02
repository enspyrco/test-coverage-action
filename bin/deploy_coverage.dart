import 'dart:io';

import 'package:deploy_coverage/firebase_hosting_api.dart';
import 'package:deploy_coverage/upload_data.dart';

void main(List<String> arguments) async {
  var packageName = Platform.environment['INPUT_PACKAGE-NAME'] ?? '';
  // var key = Platform.environment['INPUT_SERVICE-ACCOUNT-KEY'];
  var key = File('key.json').readAsStringSync();

  var api = await FirebaseHostingApi.create(key: key);

  final uploadData = await UploadData.createFrom(directory: arguments.first);

  var currentVersion = await api.getCurrentVersion();

  // Allow coverage data for different packages to be uploaded at different
  // times without overwriting everything.
  if (packageName.isNotEmpty) {
    var currentFiles = await api.listFiles(versionName: currentVersion);

    // Add current file paths and hashes to upload data, if not from package.
    for (var file in currentFiles) {
      var firstSegment = file.path.split('/').elementAt(1);

      if (firstSegment != packageName && firstSegment != '__') {
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
