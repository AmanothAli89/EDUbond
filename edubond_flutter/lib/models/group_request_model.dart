import '../core/constants/firestore_collections.dart';

class GroupRequestModel {
  const GroupRequestModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.subject,
    required this.requester,
    this.teacher,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String subject;
  final String requester;
  final String? teacher;
  final String status;
  final int timestamp;

  factory GroupRequestModel.fromMap(Map<String, dynamic> map) {
    return GroupRequestModel(
      id: (map[FirestoreFields.id] as String?) ?? '',
      groupId: (map[FirestoreFields.groupId] as String?) ?? '',
      groupName: (map[FirestoreFields.groupName] as String?) ?? '',
      subject: (map[FirestoreFields.subject] as String?) ?? '',
      requester: (map[FirestoreFields.requester] as String?) ?? '',
      teacher: map[FirestoreFields.teacher] as String?,
      status: (map[FirestoreFields.status] as String?) ?? 'pending',
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.id: id,
      FirestoreFields.groupId: groupId,
      FirestoreFields.groupName: groupName,
      FirestoreFields.subject: subject,
      FirestoreFields.requester: requester,
      if (teacher != null) FirestoreFields.teacher: teacher,
      FirestoreFields.status: status,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
