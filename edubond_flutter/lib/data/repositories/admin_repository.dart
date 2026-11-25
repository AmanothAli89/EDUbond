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
  AdminRepository(
    this._firestore, {
    this.isAdminAuthorized,
  });

  final FirestoreDataSource _firestore;
  final bool Function()? isAdminAuthorized;

  void _ensureAuthorized() {
    final check = isAdminAuthorized;
    if (check != null && !check()) {
      throw StateError('Unauthorized: Admin authentication is required.');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    _ensureAuthorized();
    final records = await _firestore.getCollectionRecords(
      FirestoreCollections.users,
    );
    return records
        .map((r) => UserModel.fromMap(r.data, fallbackUid: r.id))
        .toList();
  }

  Future<void> removeUserDocument(String uid) {
    _ensureAuthorized();
    return _firestore.deleteDoc(FirestoreCollections.users, uid);
  }

  Future<void> assignTeacherRole({
    required String email,
    required String subject,
  }) {
    _ensureAuthorized();
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
    _ensureAuthorized();
    final records = await _firestore.queryRecords(
      FirestoreCollections.userRoles,
      isEqualTo: {FirestoreFields.role: 'teacher'},
    );
    return records
        .map((r) => UserRoleModel.fromMap(r.data, docId: r.id))
        .toList();
  }

  Future<void> removeTeacherRoleByDocId(String docId) {
    _ensureAuthorized();
    return _firestore.deleteDoc(FirestoreCollections.userRoles, docId);
  }

  Future<void> removeTeacherRole({
    required String email,
    required String subject,
  }) {
    _ensureAuthorized();
    return removeTeacherRoleByDocId(
      DocIdHelper.emailSubjectDocId(email, subject),
    );
  }

  Future<List<QuizAttemptModel>> getBlockedTeachers() async {
    _ensureAuthorized();
    final records = await _firestore.queryRecords(
      FirestoreCollections.quizAttempts,
      isEqualTo: {FirestoreFields.blocked: true},
    );
    return records.map((r) => QuizAttemptModel.fromMap(r.data)).toList();
  }

  Future<void> unblockTeacher({
    required String email,
    required String subject,
  }) {
    _ensureAuthorized();
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

  Future<WeeklyReportsSummary> fetchWeeklyReports({DateTime? anchorNow}) async {
    _ensureAuthorized();
    final now = anchorNow ?? DateTime.now();
    final weekAgoDate = now.subtract(const Duration(days: 7));
    final weekAgoMs = weekAgoDate.millisecondsSinceEpoch;

    final userRecords = await _firestore.getCollectionRecords(
      FirestoreCollections.users,
    );
    final groupRecords = await _firestore.queryRecords(
      FirestoreCollections.groups,
      isGreaterThanOrEqualTo: {FirestoreFields.timestamp: weekAgoMs},
    );
    final teacherRecords = await _firestore.queryRecords(
      FirestoreCollections.userRoles,
      isEqualTo: {FirestoreFields.role: 'teacher'},
    );

    final usersWeekly = _bucketByWeekday(
      userRecords.map((r) => r.data[FirestoreFields.updatedAt]),
      since: weekAgoDate,
      now: now,
    );
    final groupsWeekly = _bucketByWeekday(
      groupRecords.map((r) => r.data[FirestoreFields.timestamp]),
      since: weekAgoDate,
      now: now,
    );
    final teachersWeekly = _bucketByWeekday(
      teacherRecords.map((r) => r.data[FirestoreFields.timestamp]),
      since: weekAgoDate,
      now: now,
    );

    return WeeklyReportsSummary(
      totalUsers: userRecords.length,
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
      if (date != null && !date.isBefore(since) && !date.isAfter(now)) {
        final day = DateFormatter.formatWeekday(date);
        if (counts.containsKey(day)) {
          counts[day] = (counts[day] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
