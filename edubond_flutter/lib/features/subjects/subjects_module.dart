import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class SubjectsModulePage extends StatelessWidget {
  const SubjectsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Subjects & Role Selection',
      kotlinSource: 'SubjectActivity.kt, SubjectDetailActivity.kt',
      description:
          'Backed by SubjectRepository & GroupRepository: Global subject search, new subject request submission, and Study vs Teach selection.',
    );
  }
}
