import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class ProfileModulePage extends StatelessWidget {
  const ProfileModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'User Profile',
      kotlinSource: 'UserProfileActivity.kt',
      description:
          'Backed by AuthRepository: View & edit display name and biodata, re-authenticate & update App Password.',
    );
  }
}
