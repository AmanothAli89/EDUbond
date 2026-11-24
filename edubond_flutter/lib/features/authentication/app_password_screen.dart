import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../data/repositories/auth_repository.dart';

class AppPasswordScreen extends ConsumerStatefulWidget {
  const AppPasswordScreen({super.key, required this.outcome});

  final GoogleSignInOutcome outcome;

  @override
  ConsumerState<AppPasswordScreen> createState() => _AppPasswordScreenState();
}

class _AppPasswordScreenState extends ConsumerState<AppPasswordScreen> {
  final _passCtrl = TextEditingController();
  bool _visible = false;
  bool _verifying = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pass = _passCtrl.text.trim();
    if (pass.isEmpty) {
      showEduSnackBar(context, 'Please enter your app password.');
      return;
    }

    setState(() => _verifying = true);
    try {
      await ref.read(authRepositoryProvider).verifyAppPasswordAfterGoogle(
            uid: widget.outcome.uid,
            email: widget.outcome.email,
            username: widget.outcome.username,
            photoUrl: widget.outcome.photoUrl,
            password: pass,
          );
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Wrong password.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _goBack() async {
    await ref.read(authRepositoryProvider).logout();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.adminLoginTop,
                AppColors.adminLoginMid,
                AppColors.adminLoginBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.appPasswordBlueLight,
                              AppColors.appPasswordBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: CustomPaint(
                            size: Size(40, 40),
                            painter: LockBadgePainter(
                              shackleColor: Colors.white,
                              bodyColor: Colors.white,
                              keyholeColor: AppColors.appPasswordBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Enter App Password',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Gmail: ${widget.outcome.email}',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter your app password to continue.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSlate),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passCtrl,
                            obscureText: !_visible,
                            decoration: const InputDecoration(
                              hintText: 'App Password',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _visible = !_visible),
                          child: CustomPaint(
                            size: const Size(24, 24),
                            painter: EyeTogglePainter(isClosed: !_visible),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appPasswordBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _verifying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _goBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputSurface,
                        foregroundColor: const Color(0xFF1F2937),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
