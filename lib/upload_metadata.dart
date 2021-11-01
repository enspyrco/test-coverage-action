import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:deploy_coverage/constants.dart';

class UploadMetadata {
  final JsonMap _filesJson = {'files': <String, Object?>{}};
  final _bytesFor = <String, Uint8List>{};

  JsonMap get filesJson => _filesJson;
  Map<String, Uint8List> get bytesFor => _bytesFor;

  Future<void> calculateHashes() async {
    await _addHashes(
        dir: Directory('html'),
        json: _filesJson['files'] as JsonMap,
        bytesFor: _bytesFor);
  }

  Future<void> _addHashes(
      {required Directory dir,
      required JsonMap json,
      required Map<String, Uint8List> bytesFor}) async {
    final List<FileSystemEntity> entities = await dir.list().toList();

    for (var entity in entities) {
      if (entity is File) {
        var bytes = entity.readAsBytesSync();
        var digest = sha256.convert(bytes);

        json["/${entity.path.replaceFirst('.gz', '')}"] = '$digest';
        bytesFor['$digest'] = bytes;
      } else if (entity is Directory) {
        await _addHashes(dir: entity, json: json, bytesFor: bytesFor);
      }
    }
  }
}
