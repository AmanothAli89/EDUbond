import '../core/constants/firestore_collections.dart';

class UserRoleModel {
  const UserRoleModel({
    this.docId = '',
    required this.email,
    required this.subject,
    required this.role,
    this.score = 0,
    required this.timestamp,
  });

  final String docId;
  final String email;
  final String subject;
  final String role; // 'learner' or 'teacher'
  final int score;
  final int timestamp;

  bool get isTeacher => role == 'teacher';

  factory UserRoleModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    return UserRoleModel(
      docId: docId,
      email: (map[FirestoreFields.email] as String?) ?? '',
      subject: (map[FirestoreFields.subject] as String?) ?? '',
      role: (map[FirestoreFields.role] as String?) ?? 'learner',
      score: (map[FirestoreFields.score] as num?)?.toInt() ?? 0,
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.email: email,
      FirestoreFields.subject: subject,
      FirestoreFields.role: role,
      FirestoreFields.score: score,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
