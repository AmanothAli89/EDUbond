import '../core/constants/firestore_collections.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.groupId,
    required this.senderEmail,
    required this.message,
    this.fileUrl,
    this.fileType,
    this.fileName,
    required this.timestamp,
    required this.seenBy,
  });

  final String id;
  final String groupId;
  final String senderEmail;
  final String message;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final int timestamp;
  final List<String> seenBy;

  bool get hasAttachment => fileUrl != null && fileUrl!.isNotEmpty;
  bool get isMeeting => fileType == 'meeting';

  factory MessageModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    final rawSeenBy = map[FirestoreFields.seenBy] as List<dynamic>? ?? const [];
    return MessageModel(
      id: docId.isNotEmpty ? docId : ((map[FirestoreFields.id] as String?) ?? ''),
      groupId: (map[FirestoreFields.groupId] as String?) ?? '',
      senderEmail: (map[FirestoreFields.senderEmail] as String?) ?? '',
      message: (map[FirestoreFields.message] as String?) ?? '',
      fileUrl: map[FirestoreFields.fileUrl] as String?,
      fileType: map[FirestoreFields.fileType] as String?,
      fileName: map[FirestoreFields.fileName] as String?,
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
      seenBy: rawSeenBy.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.groupId: groupId,
      FirestoreFields.senderEmail: senderEmail,
      FirestoreFields.message: message,
      FirestoreFields.fileUrl: fileUrl,
      FirestoreFields.fileType: fileType,
      FirestoreFields.fileName: fileName,
      FirestoreFields.timestamp: timestamp,
      FirestoreFields.seenBy: seenBy,
    };
  }
}
