import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class GroupsModulePage extends StatelessWidget {
  const GroupsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'My Groups',
      kotlinSource: 'MyGroupsActivity.kt',
      description:
          'Backed by GroupRepository: Lists all study groups where the current user is a member or teacher.',
    );
  }
}
