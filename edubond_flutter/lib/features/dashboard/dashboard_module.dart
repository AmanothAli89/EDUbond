import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class DashboardModulePage extends StatelessWidget {
  const DashboardModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'User Dashboard',
      kotlinSource: 'UserHomeActivity.kt',
      description:
          'Backed by AuthRepository: User greeting hero card, initials badge, 2x2 grid navigation (Search & Learn, Group Requests, My Groups, Logout).',
    );
  }
}
