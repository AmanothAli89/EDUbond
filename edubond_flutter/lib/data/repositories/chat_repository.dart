import 'dart:typed_data';
import '../../core/constants/firestore_collections.dart';
import '../../models/message_model.dart';
import '../../models/note_model.dart';
import '../datasources/catbox_upload_datasource.dart';
import '../datasources/firebase_storage_datasource.dart';
import '../datasources/firestore_datasource.dart';

class ChatRepository {
  ChatRepository({
    required FirestoreDataSource firestoreDataSource,
    required CatboxUploadDataSource catboxUploadDataSource,
    required FirebaseStorageDataSource storageDataSource,
  })  : _firestore = firestoreDataSource,
        _catbox = catboxUploadDataSource,
        _storage = storageDataSource;

  final FirestoreDataSource _firestore;
  final CatboxUploadDataSource _catbox;
  final FirebaseStorageDataSource _storage;

  Stream<List<MessageModel>> watchGroupMessages(String groupId) {
    return _firestore
        .watchSubcollection(
          FirestoreCollections.groups,
          groupId,
          FirestoreCollections.messagesSubcollection,
          orderByField: FirestoreFields.timestamp,
        )
        .map(
          (records) => records
              .map((r) => MessageModel.fromMap(r.data, docId: r.id))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderEmail,
    required String messageText,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    final msg = MessageModel(
      id: '',
      groupId: groupId,
      senderEmail: senderEmail,
      message: messageText,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      seenBy: [senderEmail],
    );
    await _firestore.addSubcollectionDoc(
      FirestoreCollections.groups,
      groupId,
      FirestoreCollections.messagesSubcollection,
      msg.toMap(),
    );

    await _firestore.logActivity(senderEmail, 'Sent a message in group: $groupId');
  }

  Future<void> markMessageAsRead({
    required String groupId,
    required String messageId,
    required String email,
  }) {
    return _firestore.arrayUnionSubcollectionField(
      FirestoreCollections.groups,
      groupId,
      FirestoreCollections.messagesSubcollection,
      messageId,
      FirestoreFields.seenBy,
      email,
    );
  }

  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) {
    return _firestore.deleteSubcollectionDoc(
      FirestoreCollections.groups,
      groupId,
      FirestoreCollections.messagesSubcollection,
      messageId,
    );
  }

  Future<void> shareMeetingLink({
    required String groupId,
    required String senderEmail,
    required String meetingUrl,
  }) {
    final platform = detectMeetingPlatform(meetingUrl);
    return sendMessage(
      groupId: groupId,
      senderEmail: senderEmail,
      messageText: 'Scheduled a $platform meeting',
      fileUrl: meetingUrl.trim(),
      fileType: 'meeting',
      fileName: platform,
    );
  }

  static String detectMeetingPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('zoom')) return 'Zoom';
    if (lower.contains('meet.google')) return 'Google Meet';
    if (lower.contains('jitsi') || lower.contains('jit.si')) return 'Jitsi';
    return 'Live';
  }

  /// Primary upload path preserving original Kotlin `uploadFileFree` behavior:
  /// uploads via Catbox (`https://catbox.moe/user/api.php`, `reqtype=fileupload`)
  /// and saves the resulting file URL as a group message without silently
  /// switching storage providers on failure.
  Future<String> uploadAndShareFile({
    required String groupId,
    required String senderEmail,
    required Uint8List bytes,
    required String fileName,
    required String fileType,
    void Function(double progress)? onProgress,
  }) async {
    final url = await _catbox.uploadFileBytes(
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
    );

    await sendMessage(
      groupId: groupId,
      senderEmail: senderEmail,
      messageText: 'Shared a file',
      fileUrl: url,
      fileType: fileType,
      fileName: fileName,
    );
    return url;
  }

  /// Firebase Storage helper method mirroring Kotlin `uploadFileToFirebase`.
  Future<String> uploadAndShareFileToFirebaseStorage({
    required String groupId,
    required String senderEmail,
    required Uint8List bytes,
    required String fileName,
    required String fileType,
    void Function(double progress)? onProgress,
  }) async {
    final url = await _storage.uploadGroupFile(
      groupId: groupId,
      bytes: bytes,
      fileName: fileName,
      contentType: fileType,
      onProgress: onProgress,
    );

    await sendMessage(
      groupId: groupId,
      senderEmail: senderEmail,
      messageText: 'Shared a file',
      fileUrl: url,
      fileType: fileType,
      fileName: fileName,
    );
    return url;
  }

  Future<void> addNote({
    required String groupId,
    required String title,
    required String url,
    required String type,
    required String byEmail,
  }) {
    final note = NoteModel(
      groupId: groupId,
      title: title,
      url: url,
      type: type,
      by: byEmail,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    return _firestore.addDoc(FirestoreCollections.notes, note.toMap());
  }

  Future<List<NoteModel>> getNotes(String groupId) async {
    final records = await _firestore.queryRecords(
      FirestoreCollections.notes,
      isEqualTo: {FirestoreFields.groupId: groupId},
      orderByField: FirestoreFields.timestamp,
      descending: true,
    );
    return records.map((r) => NoteModel.fromMap(r.data)).toList();
  }
}
