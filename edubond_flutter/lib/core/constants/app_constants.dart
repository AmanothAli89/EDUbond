/// Application-wide constants preserving the exact EduBond rules and configuration.
abstract final class AppConstants {
  static const String appName = 'EduBond';
  static const String appTagline = 'Digital Platform for Academic Peers';
  static const String androidPackageId = 'com.example.peermatrix';

  // Local Storage
  static const String currentUserPrefKey = 'current_user';
  static const String quizSetsPrefPrefix = 'quiz_sets_';

  // Teacher Qualification Quiz Rules
  static const int quizDurationSeconds = 300; // 5 minutes
  static const int quizTotalQuestions = 10;
  static const int quizPassingScore = 7;
  static const int quizMaxAttempts = 2;
  static const int adminQuizSetCount = 4;

  // Google Sign-In Server Client ID (client_type: 3 from google-services.json)
  static const String googleWebClientId =
      '850714985586-f332vkjs0415ef9r6reoe7suade92jbn.apps.googleusercontent.com';

  // Cloud File Upload Endpoint
  static const String catboxUploadUrl = 'https://catbox.moe/user/api.php';

  // Developer Info (About Us)
  static const String developerName = 'Md. Lemon Islam Bappy';
  static const String developerDegree =
      'B.Sc. in Computer Science and Engineering (CSE)\nBangladesh Army University of Science and Technology (BAUST)';
  static const String developerEmail = 'mdlemonislambappy@gmail.com';
  static const String developerLinkedIn =
      'https://www.linkedin.com/in/md-lemon-islam-bappy-4116a61b8/';
  static const String developerGitHub = 'https://github.com/bappy-81';

  // 16 Core Subjects seeded to Firestore if subjects collection is empty
  static const List<String> coreSubjects = [
    'Software Engineering',
    'Computer Architecture',
    'Data Communication',
    'Microprocessor',
    'Compiler',
    'Data Structure',
    'Database Management System',
    'Operating System',
    'Computer Network',
    'Artificial Intelligence',
    'Algorithm',
    'Discrete Mathematics',
    'গনিত ৯-১০',
    'উচ্চতর গনিত ৯-১০',
    'পদার্থবিজ্ঞান ৯-১০',
    'অর্থনীতি ৯-১০',
  ];

  // 9 Subjects with pre-seeded local/cloud MCQ banks
  static const List<String> seededQuizSubjects = [
    'Software Engineering',
    'Computer Architecture',
    'Data Communication',
    'Microprocessor',
    'Compiler',
    'গনিত ৯-১০',
    'উচ্চতর গনিত ৯-১০',
    'পদার্থবিজ্ঞান ৯-১০',
    'অর্থনীতি ৯-১০',
  ];
}
