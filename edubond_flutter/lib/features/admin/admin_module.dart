import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class AdminModulePage extends StatelessWidget {
  const AdminModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Admin Panel',
      kotlinSource:
          'AdminActivity.kt, AdminUserActivity.kt, AdminTeacherActivity.kt, AdminSubjectActivity.kt, AdminQuizActivity.kt',
      description:
          'Backed by AdminRepository, SubjectRepository & QuizRepository: Manage users, active/blocked teachers, subjects, pending requests, and 4x10 MCQ sets.',
    );
  }
}
