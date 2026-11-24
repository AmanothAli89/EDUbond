import 'package:material_ui/material_ui.dart';
import '../../features/admin/admin_module.dart';
import '../../features/authentication/authentication_module.dart';
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
import '../../features/subjects/subjects_module.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String subjects = '/subjects';
  static const String quiz = '/quiz';
  static const String groups = '/groups';
  static const String chat = '/chat';
  static const String requests = '/requests';
  static const String sharedFiles = '/shared-files';
  static const String groupInfo = '/group-info';
  static const String admin = '/admin';
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
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthenticationModulePage(),
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
      case AppRoutes.quiz:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const QuizModulePage(),
        );
      case AppRoutes.groups:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GroupsModulePage(),
        );
      case AppRoutes.chat:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ChatModulePage(),
        );
      case AppRoutes.requests:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RequestsModulePage(),
        );
      case AppRoutes.sharedFiles:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SharedFilesModulePage(),
        );
      case AppRoutes.groupInfo:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GroupInfoModulePage(),
        );
      case AppRoutes.admin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminModulePage(),
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
