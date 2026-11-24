import '../core/constants/firestore_collections.dart';

class QuizAttemptModel {
  const QuizAttemptModel({
    required this.email,
    required this.subject,
    required this.attempts,
    required this.totalAttempts,
    required this.blocked,
    required this.lastPassed,
    required this.timestamp,
  });

  final String email;
  final String subject;
  final int attempts;
  final int totalAttempts;
  final bool blocked;
  final bool lastPassed;
  final int timestamp;

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) {
    return QuizAttemptModel(
      email: (map[FirestoreFields.email] as String?) ?? '',
      subject: (map[FirestoreFields.subject] as String?) ?? '',
      attempts: (map[FirestoreFields.attempts] as num?)?.toInt() ?? 0,
      totalAttempts: (map[FirestoreFields.totalAttempts] as num?)?.toInt() ?? 0,
      blocked: (map[FirestoreFields.blocked] as bool?) ?? false,
      lastPassed: (map[FirestoreFields.lastPassed] as bool?) ?? false,
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.email: email,
      FirestoreFields.subject: subject,
      FirestoreFields.attempts: attempts,
      FirestoreFields.totalAttempts: totalAttempts,
      FirestoreFields.blocked: blocked,
      FirestoreFields.lastPassed: lastPassed,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
