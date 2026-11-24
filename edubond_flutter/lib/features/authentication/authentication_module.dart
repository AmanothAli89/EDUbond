import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../data/repositories/auth_repository.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBgTop,
              AppColors.authBgMiddle,
              AppColors.authBgBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFAAB7C8)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📖', style: TextStyle(fontSize: 38)),
            SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15.5, color: AppColors.textCharcoal),
        ),
        SizedBox(height: 28),
      ],
    );
  }
}

class AuthStyledInput extends StatelessWidget {
  const AuthStyledInput({
    super.key,
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.authInputSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSlate),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textCharcoal,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}

class AuthSolidButton extends StatelessWidget {
  const AuthSolidButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.textColor = Colors.white,
    this.loading = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class AuthenticationModulePage extends ConsumerStatefulWidget {
  const AuthenticationModulePage({super.key});

  @override
  ConsumerState<AuthenticationModulePage> createState() =>
      _AuthenticationModulePageState();
}

class _AuthenticationModulePageState
    extends ConsumerState<AuthenticationModulePage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      showEduSnackBar(context, 'Please enter your Gmail and password.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .loginWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      showEduSnackBar(context, 'Login successful.');
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showEduSnackBar(context, 'Login failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isBusy = true);
    try {
      final outcome =
          await ref.read(authRepositoryProvider).authenticateWithGoogle();
      if (!mounted) return;

      if (outcome.nextStep == GoogleAuthNextStep.setAppPassword) {
        Navigator.of(context).pushNamed(
          AppRoutes.setAppPassword,
          arguments: outcome,
        );
      } else {
        Navigator.of(context).pushNamed(
          AppRoutes.appPassword,
          arguments: outcome,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'account-exists-with-different-credential') {
        Navigator.of(context).pushNamed(
          AppRoutes.appPassword,
          arguments: GoogleSignInOutcome(
            nextStep: GoogleAuthNextStep.verifyAppPassword,
            uid: '',
            email: _emailCtrl.text.trim(),
            username: '',
            photoUrl: '',
          ),
        );
      } else {
        showEduSnackBar(
          context,
          'Authentication failed: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Google login failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandHeader(),
          const Text(
            'User Login',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 16),
          AuthStyledInput(
            controller: _emailCtrl,
            hint: 'Enter your Gmail',
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(
              Icons.mail_outline,
              color: AppColors.textGrayIcon,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          AuthStyledInput(
            controller: _passwordCtrl,
            hint: 'App Password',
            obscureText: !_passwordVisible,
            prefix: const SizedBox(
              width: 24,
              child: Center(
                child: Text(
                  '●',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGrayIcon,
                  ),
                ),
              ),
            ),
            suffix: GestureDetector(
              onTap: () => setState(() => _passwordVisible = !_passwordVisible),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: CustomPaint(
                    size: const Size(24, 24),
                    painter: EyeTogglePainter(isClosed: !_passwordVisible),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          AuthSolidButton(
            label: 'Login',
            color: AppColors.authBlue,
            loading: _isBusy,
            onPressed: _handleEmailLogin,
          ),
          TextButton(
            onPressed: _isBusy
                ? null
                : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 16, color: AppColors.linkNavy),
            ),
          ),
          const SizedBox(height: 4),
          AuthSolidButton(
            label: 'Continue with Google',
            color: AppColors.googleTeal,
            loading: _isBusy,
            onPressed: _handleGoogleSignIn,
          ),
          const SizedBox(height: 12),
          AuthSolidButton(
            label: 'Login as Admin',
            color: AppColors.deepPurple,
            loading: _isBusy,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminLogin),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _isBusy
                ? null
                : () => Navigator.of(context).pushNamed(AppRoutes.aboutUs),
            child: const Text(
              'About Us',
              style: TextStyle(fontSize: 16, color: AppColors.linkNavy),
            ),
          ),
        ],
      ),
    );
  }
}
