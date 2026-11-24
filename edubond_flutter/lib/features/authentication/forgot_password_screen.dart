import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import 'authentication_module.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showEduSnackBar(context, 'Please enter a valid Gmail address.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      showEduSnackBar(
        context,
        'Password reset email sent. Please check your Gmail inbox or spam folder.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Password reset failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Forgot Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter the Gmail account you used before. A password reset email will be sent to that address.',
            style: TextStyle(fontSize: 15, color: AppColors.textSlate),
          ),
          const SizedBox(height: 20),
          AuthStyledInput(
            controller: _emailCtrl,
            hint: 'Enter your Gmail',
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(
              Icons.mail_outline,
              color: AppColors.textGrayIcon,
            ),
          ),
          const SizedBox(height: 20),
          AuthSolidButton(
            label: 'Send Reset Email',
            color: AppColors.brandBlue,
            loading: _sending,
            onPressed: _sendReset,
          ),
          const SizedBox(height: 12),
          AuthSolidButton(
            label: 'Back to Login',
            color: AppColors.inputSurface,
            textColor: AppColors.textSlate,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
