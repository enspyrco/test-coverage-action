import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:deploy_coverage/constants.dart';
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

    var versionJson = jsonDecode(response.body);
    return versionJson['name'];
  }

  Future<List<String>> populateFiles({
    required JsonMap json,
    required String versionName,
  }) async {
    var populateUri = Uri.https(host, '/v1beta1/$versionName:populateFiles');

    var populateResponse = await _client.post(
      populateUri,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(json),
    );

    var responseJson = jsonDecode(populateResponse.body);

    _uploadUrl = responseJson['uploadUrl'];

    return List<String>.from(
        (responseJson['uploadRequiredHashes'] ?? []) as List<dynamic>);
  }

  Future<void> uploadFiles({
    required List<String> requiredHashes,
    required Map<String, Uint8List> bytesFor,
  }) async {
    for (var hash in requiredHashes) {
      var uploadResponse = await _client.post(Uri.parse('$_uploadUrl/$hash'),
          headers: {'Content-Type': 'application/octet-stream'},
          body: bytesFor[hash]);

      print('Uploaded $hash with response: ${uploadResponse.body}');
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
