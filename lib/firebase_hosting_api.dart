import 'dart:convert';
import 'dart:io';

import 'package:deploy_coverage/constants.dart';
import 'package:deploy_coverage/upload_metadata.dart';
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
  late final Uri _versionsUri;
  late final String _uploadUrl;

  final AuthClient _client;

  FirebaseHostingApi._(AuthClient client) : _client = client {
    // var firebasercString = File(arguments.elementAt(1)).readAsStringSync();

    var firebasercString = File('.firebaserc').readAsStringSync();
    _siteId = jsonDecode(firebasercString)['projects']['default'];

    _versionsUri = Uri.https(host, 'v1beta1/sites/$_siteId/versions');
  }

  static Future<FirebaseHostingApi> create({required String key}) async {
    var credentials = ServiceAccountCredentials.fromJson(jsonDecode(key));

    var client = await clientViaServiceAccount(
        credentials, ["https://www.googleapis.com/auth/firebase.hosting"]);

    return FirebaseHostingApi._(client);
  }

  /// returns the [jsonName]
  Future<String> retrieveVersion() async {
    var response = await _client.post(_versionsUri,
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

    var versionName = jsonDecode(response.body)['name'];

    print('\n\nRetrieved version: $versionName');

    return versionName;
  }

  Future<List<String>> populateFiles({
    required UploadData uploadData,
    required String versionName,
  }) async {
    var populateUri = Uri.https(host, '/v1beta1/$versionName:populateFiles');
    print('\n\nPopulating files...');

    var populateResponse = await _client.post(
      populateUri,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(uploadData.json),
    );

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
