import 'dart:convert';
import 'dart:io';

import 'package:deploy_coverage/constants.dart';
import 'package:deploy_coverage/models/upload_data.dart';
import 'package:deploy_coverage/models/version_file.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Must be called in the right order
///
/// versionName takes the form: sites/SITE_ID/versions/VERSION_ID
///
/// You should call [closeClient] when you are done using the api.
///
class FirebaseHostingApi {
  late final String _siteId;
  late final Uri _createNewVersionUri;
  late final Uri _getCurrentVersionUri;
  late final String _uploadUrl;

  final AuthClient _client;

  FirebaseHostingApi._(AuthClient client) : _client = client {
    // var firebasercString = File(arguments.elementAt(1)).readAsStringSync();

    var firebasercString = File('.firebaserc').readAsStringSync();
    _siteId = jsonDecode(firebasercString)['projects']['default'];

    _createNewVersionUri = Uri.https(host, '/v1beta1/sites/$_siteId/versions');
    _getCurrentVersionUri = Uri.https(host, '/v1beta1/sites/$_siteId/releases');
  }

  static Future<FirebaseHostingApi> create({required String key}) async {
    var credentials = ServiceAccountCredentials.fromJson(jsonDecode(key));

    var client = await clientViaServiceAccount(
        credentials, ["https://www.googleapis.com/auth/firebase.hosting"]);

    return FirebaseHostingApi._(client);
  }

  Future<String> getCurrentVersion() async {
    var response = await _client.get(_getCurrentVersionUri,
        headers: {'Content-type': 'application/json'});

    var releases = jsonDecode(response.body)['releases'] as List;
    var current = releases.first;

    return current['version']['name'] as String;
  }

  /// returns the [versionName]
  Future<String> createNewVersion() async {
    var response = await _client.post(_createNewVersionUri,
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({
          "config": {
            "headers": [
              {
                "glob": "**",
                "headers": {"Cache-Control": "max-age=1800"}
              }
            ]
          }
        }));

    print(response.body);

    var versionName = jsonDecode(response.body)['name'];

    print('\n\nRetrieved version: $versionName');

    return versionName;
  }

  Future<List<VersionFile>> listFiles({required String versionName}) async {
    var listFilesUri = Uri.https(host, '/v1beta1/$versionName/files');
    print('\n\nListing files...');

    var listFilesResponse = await _client
        .get(listFilesUri, headers: {'Content-type': 'application/json'});
    // print(listFilesResponse.body);

    var responseJson = jsonDecode(listFilesResponse.body);

    var filesJsonList = responseJson['files'] as JsonList;

    var versionFiles = filesJsonList
        .map<VersionFile>((element) => VersionFile.fromJson(element as JsonMap))
        .toList();

    return versionFiles;
  }

  Future<List<String>> populateFiles({
    required UploadData uploadData,
    required String versionName,
  }) async {
    var populateUri = Uri.https(host, '/v1beta1/$versionName:populateFiles');
    print('\n\nPopulating files...');

    print(uploadData.json);

    var populateResponse = await _client.post(
      populateUri,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(uploadData.json),
    );
    print(populateResponse.body);

    var responseJson = jsonDecode(populateResponse.body);

    _uploadUrl = responseJson['uploadUrl'];

    var requiredHashes = List<String>.from(
        (responseJson['uploadRequiredHashes'] ?? []) as List<dynamic>);

    print('Required hashes: $requiredHashes');

    return requiredHashes;
  }

  Future<void> uploadFiles({
    required List<String> requiredHashes,
    required UploadData uploadData,
  }) async {
    int i = 1, total = requiredHashes.length;
    for (var hash in requiredHashes) {
      await _client.post(Uri.parse('$_uploadUrl/$hash'),
          headers: {'Content-Type': 'application/octet-stream'},
          body: uploadData.bytesFor[hash]);

      print('Uploaded ${i++}/$total - ${uploadData.pathFor[hash]}.');
    }
  }

  Future<void> finalizeStatus({required String versionName}) async {
    final statusUri =
        Uri.https(host, '/v1beta1/$versionName', {'update_mask': 'status'});
    print(statusUri);

    var statusResponse = await _client.patch(statusUri,
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({'status': 'FINALIZED'}));

    print(statusResponse.body);
  }

  Future<void> release({required String versionName}) async {
    final releaseUri = Uri.https(
        host, '/v1beta1/sites/$_siteId/releases', {'versionName': versionName});
    var releaseResponse = await _client.post(releaseUri);

    print(releaseResponse.body);
  }

  void closeClient() => _client.close();
}
