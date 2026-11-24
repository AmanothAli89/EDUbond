import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return _firestore.raw
        .collection(FirestoreCollections.groups)
        .doc(groupId)
        .collection(FirestoreCollections.messagesSubcollection)
        .orderBy(FirestoreFields.timestamp)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
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
    await _firestore.raw
        .collection(FirestoreCollections.groups)
        .doc(groupId)
        .collection(FirestoreCollections.messagesSubcollection)
        .add(msg.toMap());

    await _firestore.logActivity(senderEmail, 'Sent a message in group: $groupId');
  }

  Future<void> markMessageAsRead({
    required String groupId,
    required String messageId,
    required String email,
  }) {
    return _firestore.raw
        .collection(FirestoreCollections.groups)
        .doc(groupId)
        .collection(FirestoreCollections.messagesSubcollection)
        .doc(messageId)
        .update({
      FirestoreFields.seenBy: FieldValue.arrayUnion([email]),
    });
  }

  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) {
    return _firestore.raw
        .collection(FirestoreCollections.groups)
        .doc(groupId)
        .collection(FirestoreCollections.messagesSubcollection)
        .doc(messageId)
        .delete();
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
    if (url.contains('zoom')) return 'Zoom';
    if (url.contains('meet.google')) return 'Google Meet';
    if (url.contains('jitsi')) return 'Jitsi';
    return 'Live';
  }

  Future<void> uploadAndShareFile({
    required String groupId,
    required String senderEmail,
    required Uint8List bytes,
    required String fileName,
    required String fileType,
    bool useFirebaseStorageFallback = true,
  }) async {
    String url;
    try {
      url = await _catbox.uploadFileBytes(bytes: bytes, fileName: fileName);
    } catch (e) {
      if (!useFirebaseStorageFallback) rethrow;
      url = await _storage.uploadGroupFile(
        groupId: groupId,
        bytes: bytes,
        fileName: fileName,
        contentType: fileType,
      );
    }

    await sendMessage(
      groupId: groupId,
      senderEmail: senderEmail,
      messageText: 'Shared a file',
      fileUrl: url,
      fileType: fileType,
      fileName: fileName,
    );
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
    final snap = await _firestore.raw
        .collection(FirestoreCollections.notes)
        .where(FirestoreFields.groupId, isEqualTo: groupId)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .get();
    return snap.docs.map((doc) => NoteModel.fromMap(doc.data())).toList();
  }
}
