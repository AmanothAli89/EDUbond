import '../core/constants/firestore_collections.dart';

class NoteModel {
  const NoteModel({
    required this.groupId,
    required this.title,
    required this.url,
    required this.type,
    required this.by,
    required this.timestamp,
  });

  final String groupId;
  final String title;
  final String url;
  final String type;
  final String by;
  final int timestamp;

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      groupId: (map[FirestoreFields.groupId] as String?) ?? '',
      title: (map[FirestoreFields.title] as String?) ?? '',
      url: (map[FirestoreFields.url] as String?) ?? '',
      type: (map[FirestoreFields.type] as String?) ?? '',
      by: (map[FirestoreFields.by] as String?) ?? '',
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.groupId: groupId,
      FirestoreFields.title: title,
      FirestoreFields.url: url,
      FirestoreFields.type: type,
      FirestoreFields.by: by,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
