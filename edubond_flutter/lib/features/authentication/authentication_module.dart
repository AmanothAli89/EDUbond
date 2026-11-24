import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class AuthenticationModulePage extends StatelessWidget {
  const AuthenticationModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Authentication',
      kotlinSource: 'MainActivity.kt, AuthUIHelper.kt, AuthViews.kt',
      description:
          'Backed by AuthRepository: Email/Password sign-in, Google Sign-In + App Password linking, Forgot Password, Admin Login, and Developer About Us.',
    );
  }
}
