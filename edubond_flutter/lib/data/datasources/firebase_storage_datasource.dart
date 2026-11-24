import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageDataSource {
  FirebaseStorageDataSource(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadGroupFile({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final path =
        'groups/$groupId/shared_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
