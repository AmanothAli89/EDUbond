import 'package:material_ui/material_ui.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/admin/admin_module.dart';
import '../../features/admin/admin_quiz_screen.dart';
import '../../features/admin/admin_subjects_screen.dart';
import '../../features/admin/admin_teachers_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/authentication/about_us_screen.dart';
import '../../features/authentication/admin_login_screen.dart';
import '../../features/authentication/app_password_screen.dart';
import '../../features/authentication/authentication_module.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/authentication/set_app_password_screen.dart';
import '../../features/chat/chat_module.dart';
import '../../features/dashboard/dashboard_module.dart';
import '../../features/group_info/group_info_module.dart';
import '../../features/groups/groups_module.dart';
import '../../features/profile/profile_module.dart';
import '../../features/quiz/quiz_module.dart';
import '../../features/reports/reports_module.dart';
import '../../features/requests/requests_module.dart';
import '../../features/shared_files/shared_files_module.dart';
import '../../features/splash/splash_gate_page.dart';
import '../../features/subjects/subject_detail_screen.dart';
import '../../features/subjects/subjects_module.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String forgotPassword = '/forgot-password';
  static const String adminLogin = '/admin-login';
  static const String setAppPassword = '/set-app-password';
  static const String appPassword = '/app-password';
  static const String aboutUs = '/about-us';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String subjects = '/subjects';
  static const String subjectDetail = '/subject-detail';
  static const String quiz = '/quiz';
  static const String groups = '/groups';
  static const String chat = '/chat';
  static const String requests = '/requests';
  static const String sharedFiles = '/shared-files';
  static const String groupInfo = '/group-info';
  static const String admin = '/admin';
  static const String adminUsers = '/admin-users';
  static const String adminTeachers = '/admin-teachers';
  static const String adminSubjects = '/admin-subjects';
  static const String adminQuiz = '/admin-quiz';
  static const String reports = '/reports';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashGatePage(),
        );
      case AppRoutes.auth:
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, _, _) => const AuthenticationModulePage(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ForgotPasswordScreen(),
        );
      case AppRoutes.adminLogin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminLoginScreen(),
        );
      case AppRoutes.setAppPassword:
        final outcome = settings.arguments as GoogleSignInOutcome;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SetAppPasswordScreen(outcome: outcome),
        );
      case AppRoutes.appPassword:
        final outcome = settings.arguments as GoogleSignInOutcome;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AppPasswordScreen(outcome: outcome),
        );
      case AppRoutes.aboutUs:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AboutUsScreen(),
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DashboardModulePage(),
        );
      case AppRoutes.profile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ProfileModulePage(),
        );
      case AppRoutes.subjects:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SubjectsModulePage(),
        );
      case AppRoutes.subjectDetail:
        final subject = (settings.arguments as String?) ?? '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SubjectDetailScreen(subject: subject),
        );
      case AppRoutes.quiz:
        final subject = (settings.arguments as String?) ?? '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => QuizModulePage(subject: subject),
        );
      case AppRoutes.groups:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GroupsModulePage(),
        );
      case AppRoutes.chat:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ChatModulePage(
            groupId: (args['groupId'] as String?) ?? '',
            groupName: (args['groupName'] as String?) ?? 'Group',
          ),
        );
      case AppRoutes.requests:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RequestsModulePage(),
        );
      case AppRoutes.sharedFiles:
        final groupId = (settings.arguments as String?) ?? '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SharedFilesModulePage(groupId: groupId),
        );
      case AppRoutes.groupInfo:
        final groupId = (settings.arguments as String?) ?? '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GroupInfoModulePage(groupId: groupId),
        );
      case AppRoutes.admin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminModulePage(),
        );
      case AppRoutes.adminUsers:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminUsersScreen(),
        );
      case AppRoutes.adminTeachers:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTeachersScreen(),
        );
      case AppRoutes.adminSubjects:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminSubjectsScreen(),
        );
      case AppRoutes.adminQuiz:
        final subject = (settings.arguments as String?) ?? '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AdminQuizEditorScreen(subject: subject),
        );
      case AppRoutes.reports:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ReportsModulePage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashGatePage(),
        );
    }
  }
}
