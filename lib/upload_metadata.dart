import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:deploy_coverage/constants.dart';

/// The data (files as bytes) and metadata (hashes, paths mapped to hashes, etc)
/// are calculated when the object is created and cannot be changed.
class UploadData {
  /// A single private constructor forces anyone wanting to create an [UploadData]
  /// to use the static function.
  UploadData._(
      {required JsonMap json,
      required Map<String, Uint8List> bytesFor,
      required Map<String, String> pathFor})
      : _uploadJson = {'files': json},
        _bytesFor = bytesFor,
        _pathFor = pathFor;

  /// A static function for asynchronously creating [UploadData] objects. All
  /// files in the given directory are used to calculate the metadata and
  /// package the file data ready for upload to Firebase Hosting.
  static Future<UploadData> createFrom({required String directory}) async {
    var numFiles = 0;
    var dir = Directory(directory);
    var json = <String, Object?>{};
    final bytesMap = <String, Uint8List>{};
    final pathMap = <String, String>{};

    final List<FileSystemEntity> entities =
        await dir.list(recursive: true).toList();

    print('Found ${entities.length} file system entities.');

    /// Calculate hashes and other metdata.
    for (var entity in entities) {
      if (entity is File) {
        numFiles++;
        var bytes = entity.readAsBytesSync();
        var digest = sha256.convert(bytes);

        print(
            'hash: ${truncate(15, digest.toString())} from .../${entity.uri.pathSegments.last} ');

        json["/${entity.path.replaceFirst('.gz', '')}"] = '$digest';
        bytesMap['$digest'] = bytes;
        pathMap['$digest'] = entity.path;
      }
    }

    print('Hashed $numFiles files.');

    // create an object from the data & metadata
    return UploadData._(json: json, bytesFor: bytesMap, pathFor: pathMap);
  }

  /// Members.
  final JsonMap _uploadJson;
  final Map<String, Uint8List> _bytesFor;
  final Map<String, String> _pathFor;

  /// Getters.
  JsonMap get json => _uploadJson;
  Map<String, Uint8List> get bytesFor => _bytesFor;
  Map<String, String> get pathFor => _pathFor;

  /// Static utility functions
  static String truncate(int cutoff, String myString) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }
}
