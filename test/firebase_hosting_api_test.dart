import 'package:deploy_coverage/firebase_hosting_api.dart';
import 'package:test/test.dart';

void main() {
  test('Firebase Hosting API', () {
    String key = '';

    expect(() => FirebaseHostingApi.create(key: key), throwsException);
  });
}
