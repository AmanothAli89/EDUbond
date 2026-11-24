import '../../core/constants/firestore_collections.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/doc_id_helper.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role_model.dart';
import '../datasources/firestore_datasource.dart';

class WeeklyReportsSummary {
  const WeeklyReportsSummary({
    required this.totalUsers,
    required this.newUsersWeekly,
    required this.newGroupsWeekly,
    required this.newTeachersWeekly,
  });

  final int totalUsers;
  final Map<String, int> newUsersWeekly;
  final Map<String, int> newGroupsWeekly;
  final Map<String, int> newTeachersWeekly;
}

class AdminRepository {
  AdminRepository(this._firestore);

  final FirestoreDataSource _firestore;

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _firestore.getCollection(FirestoreCollections.users);
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data(), fallbackUid: doc.id))
        .toList();
  }

  Future<void> removeUserDocument(String uid) {
    return _firestore.deleteDoc(FirestoreCollections.users, uid);
  }

  Future<void> assignTeacherRole({
    required String email,
    required String subject,
  }) {
    final roleId = DocIdHelper.emailSubjectDocId(email, subject);
    final role = UserRoleModel(
      docId: roleId,
      email: email,
      subject: subject,
      role: 'teacher',
      score: 10,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    return _firestore.setDoc(FirestoreCollections.userRoles, roleId, role.toMap());
  }

  Future<List<UserRoleModel>> getAllTeachers() async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.userRoles)
        .where(FirestoreFields.role, isEqualTo: 'teacher')
        .get();
    return snap.docs
        .map((doc) => UserRoleModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<void> removeTeacherRoleByDocId(String docId) {
    return _firestore.deleteDoc(FirestoreCollections.userRoles, docId);
  }

  Future<void> removeTeacherRole({
    required String email,
    required String subject,
  }) {
    return removeTeacherRoleByDocId(
      DocIdHelper.emailSubjectDocId(email, subject),
    );
  }

  Future<List<QuizAttemptModel>> getBlockedTeachers() async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.quizAttempts)
        .where(FirestoreFields.blocked, isEqualTo: true)
        .get();
    return snap.docs
        .map((doc) => QuizAttemptModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> unblockTeacher({
    required String email,
    required String subject,
  }) {
    final attemptId = DocIdHelper.emailSubjectDocId(email, subject);
    return _firestore.updateDoc(
      FirestoreCollections.quizAttempts,
      attemptId,
      {
        FirestoreFields.blocked: false,
        FirestoreFields.attempts: 0,
      },
    );
  }

  Future<WeeklyReportsSummary> fetchWeeklyReports() async {
    final now = DateTime.now();
    final weekAgoDate = now.subtract(const Duration(days: 7));
    final weekAgoMs = weekAgoDate.millisecondsSinceEpoch;

    // Fetch collections cleanly and aggregate both Timestamp and int millis fields.
    final usersSnap = await _firestore.getCollection(FirestoreCollections.users);
    final groupsSnap = await _firestore.raw
        .collection(FirestoreCollections.groups)
        .where(FirestoreFields.timestamp, isGreaterThanOrEqualTo: weekAgoMs)
        .get();
    final teachersSnap = await _firestore.raw
        .collection(FirestoreCollections.userRoles)
        .where(FirestoreFields.role, isEqualTo: 'teacher')
        .where(FirestoreFields.timestamp, isGreaterThanOrEqualTo: weekAgoMs)
        .get();

    final usersWeekly = _bucketByWeekday(
      usersSnap.docs.map((d) => d.data()[FirestoreFields.updatedAt]),
      since: weekAgoDate,
      now: now,
    );
    final groupsWeekly = _bucketByWeekday(
      groupsSnap.docs.map((d) => d.data()[FirestoreFields.timestamp]),
      since: weekAgoDate,
      now: now,
    );
    final teachersWeekly = _bucketByWeekday(
      teachersSnap.docs.map((d) => d.data()[FirestoreFields.timestamp]),
      since: weekAgoDate,
      now: now,
    );

    return WeeklyReportsSummary(
      totalUsers: usersSnap.size,
      newUsersWeekly: usersWeekly,
      newGroupsWeekly: groupsWeekly,
      newTeachersWeekly: teachersWeekly,
    );
  }

  Map<String, int> _bucketByWeekday(
    Iterable<dynamic> rawDates, {
    required DateTime since,
    required DateTime now,
  }) {
    final labels = DateFormatter.lastSevenDayLabels(now);
    final counts = <String, int>{for (final l in labels) l: 0};

    for (final raw in rawDates) {
      final date = DateFormatter.parseFirestoreDate(raw);
      if (date != null && !date.isBefore(since)) {
        final day = DateFormatter.formatWeekday(date);
        if (counts.containsKey(day)) {
          counts[day] = (counts[day] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
