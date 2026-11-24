import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class GroupInfoModulePage extends StatelessWidget {
  const GroupInfoModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Group Info & Teacher Hiring',
      kotlinSource: 'GroupInfoActivity.kt',
      description:
          'Backed by GroupRepository & SubjectRepository: Displays members, teachers, qualified teacher hiring requests, shared files link, and leave group.',
    );
  }
}
