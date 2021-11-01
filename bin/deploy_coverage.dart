import 'dart:io';

import 'package:deploy_coverage/firebase_hosting_api.dart';
import 'package:deploy_coverage/upload_metadata.dart';

void main(List<String> arguments) async {
  final api = await FirebaseHostingApi.create(
      key: File('key.json').readAsStringSync()); // arguments.first

  final upload = UploadMetadata()..calculateHashes();

  var version = await api.retrieveVersion();
  var hashes =
      await api.populateFiles(json: upload.filesJson, versionName: version);

  await api.uploadFiles(requiredHashes: hashes, bytesFor: upload.bytesFor);

  await api.finalizeStatus(versionName: version);
  await api.release(versionName: version);

  api.closeClient();
}
