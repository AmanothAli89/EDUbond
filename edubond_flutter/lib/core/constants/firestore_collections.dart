/// Exact Firestore collection and field names preserved from the Kotlin app.
/// Do NOT modify any key here without migrating existing Firestore data.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String subjects = 'subjects';
  static const String subjectRequests = 'subject_requests';
  static const String quizzes = 'quizzes';
  static const String quizAttempts = 'quiz_attempts';
  static const String userRoles = 'user_roles';
  static const String groups = 'groups';
  static const String messagesSubcollection = 'messages';
  static const String groupJoinRequests = 'group_join_requests';
  static const String teacherGroupRequests = 'teacher_group_requests';
  static const String adminConfig = 'admin_config';
  static const String adminCredentialsDoc = 'credentials';
  static const String activityLogs = 'activity_logs';
  static const String notes = 'notes';
  static const String appData = 'app_data';
  static const String appDataSubjectsDoc = 'subjects';
}

abstract final class FirestoreFields {
  // Common
  static const String id = 'id';
  static const String email = 'email';
  static const String timestamp = 'timestamp';
  static const String status = 'status';
  static const String subject = 'subject';

  // users
  static const String uid = 'uid';
  static const String username = 'username';
  static const String photoUrl = 'photoUrl';
  static const String role = 'role';
  static const String loginProvider = 'loginProvider';
  static const String googleVerified = 'googleVerified';
  static const String passwordSet = 'passwordSet';
  static const String biodata = 'biodata';
  static const String updatedAt = 'updatedAt';

  // subjects
  static const String name = 'name';
  static const String type = 'type';

  // subject_requests
  static const String by = 'by';

  // quizzes
  static const String quizJson = 'quizJson';
  static const String lastUpdated = 'lastUpdated';

  // quiz_attempts
  static const String attempts = 'attempts';
  static const String totalAttempts = 'totalAttempts';
  static const String blocked = 'blocked';
  static const String lastPassed = 'lastPassed';

  // user_roles
  static const String score = 'score';

  // groups
  static const String createdBy = 'createdBy';
  static const String members = 'members';
  static const String teachers = 'teachers';

  // messages
  static const String groupId = 'groupId';
  static const String senderEmail = 'senderEmail';
  static const String message = 'message';
  static const String fileUrl = 'fileUrl';
  static const String fileType = 'fileType';
  static const String fileName = 'fileName';
  static const String seenBy = 'seenBy';

  // requests
  static const String groupName = 'groupName';
  static const String requester = 'requester';
  static const String teacher = 'teacher';

  // admin_config
  static const String password = 'password';

  // activity_logs
  static const String action = 'action';

  // notes
  static const String title = 'title';
  static const String url = 'url';
}
