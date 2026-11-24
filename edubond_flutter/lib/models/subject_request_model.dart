import '../core/constants/firestore_collections.dart';

class SubjectRequestModel {
  const SubjectRequestModel({
    required this.id,
    required this.subject,
    required this.by,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String subject;
  final String by;
  final String status;
  final int timestamp;

  factory SubjectRequestModel.fromMap(Map<String, dynamic> map) {
    return SubjectRequestModel(
      id: (map[FirestoreFields.id] as String?) ?? '',
      subject: (map[FirestoreFields.subject] as String?) ?? '',
      by: (map[FirestoreFields.by] as String?) ?? '',
      status: (map[FirestoreFields.status] as String?) ?? 'pending',
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.id: id,
      FirestoreFields.subject: subject,
      FirestoreFields.by: by,
      FirestoreFields.status: status,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
