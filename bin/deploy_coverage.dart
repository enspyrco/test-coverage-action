import 'dart:io';

import 'package:deploy_coverage/firebase_hosting_api.dart';
import 'package:deploy_coverage/upload_metadata.dart';

void main(List<String> arguments) async {
  final api = await FirebaseHostingApi.create(
      key: File('key.json').readAsStringSync()); // arguments.first

  final upload = await UploadData.createFrom(directory: arguments.first);

  var version = await api.retrieveVersion();
  var hashes = await api.populateFiles(
    uploadData: upload,
    versionName: version,
  );

  if (hashes.isEmpty) {
    print('Finishing as there are no required hashes.');
    api.closeClient();
    return;
  }

  await api.uploadFiles(requiredHashes: hashes, uploadData: upload);

  await api.finalizeStatus(versionName: version);
  await api.release(versionName: version);

  api.closeClient();
}
