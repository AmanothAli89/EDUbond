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
    void Function(double progress)? onProgress,
  }) async {
    final path =
        'groups/$groupId/shared_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final task = ref.putData(bytes, metadata);
    final sub = onProgress != null
        ? task.snapshotEvents.listen((snap) {
            if (snap.totalBytes > 0) {
              onProgress(
                (snap.bytesTransferred / snap.totalBytes).clamp(0.0, 1.0),
              );
            }
          })
        : null;
    try {
      await task;
      onProgress?.call(1.0);
      return await ref.getDownloadURL();
    } finally {
      await sub?.cancel();
    }
  }
}
