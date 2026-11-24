import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class QuizModulePage extends StatelessWidget {
  const QuizModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Teacher Qualification Quiz',
      kotlinSource: 'TeacherQuizActivity.kt',
      description:
          'Backed by QuizRepository: 5-minute countdown timer, 10 MCQs, minimum 7/10 passing score, 2-attempt blocking policy, and auto-submit.',
    );
  }
}
