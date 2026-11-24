import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../data/repositories/auth_repository.dart';

class SetAppPasswordScreen extends ConsumerStatefulWidget {
  const SetAppPasswordScreen({super.key, required this.outcome});

  final GoogleSignInOutcome outcome;

  @override
  ConsumerState<SetAppPasswordScreen> createState() =>
      _SetAppPasswordScreenState();
}

class _SetAppPasswordScreenState extends ConsumerState<SetAppPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _saving = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final p1 = _passCtrl.text.trim();
    final p2 = _confirmCtrl.text.trim();
    if (p1.length < 6) {
      showEduSnackBar(context, 'Password must be at least 6 characters.');
      return;
    }
    if (p1 != p2) {
      showEduSnackBar(context, 'Passwords do not match.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).setAppPasswordForGoogleUser(
            uid: widget.outcome.uid,
            email: widget.outcome.email,
            username: widget.outcome.username,
            photoUrl: widget.outcome.photoUrl,
            password: p1,
          );
      if (!mounted) return;
      showEduSnackBar(context, 'Password set successfully.');
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Password setup failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelAndLogout() async {
    await ref.read(authRepositoryProvider).logout();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelAndLogout();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FBFF),
                Color(0xFFF1F8FF),
                Color(0xFFF9F7FF),
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
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFDDF8DE), Color(0xFFEFFFF1)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Center(
                          child: CustomPaint(
                            size: Size(44, 44),
                            painter: LockBadgePainter(
                              shackleColor: Color(0xFF197A43),
                              bodyColor: Color(0xFF197A43),
                              keyholeColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Text(
                          'Set App Password',
                          style: TextStyle(
                            fontSize: 27,
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
                      color: AppColors.setPassGreenBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.setPassGreenBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.setPassGreenLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.setPassGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You can use this password later to log in with your Gmail and app password.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _labeledPassword(
                    label: 'New App Password',
                    hint: 'Enter new app password',
                    controller: _passCtrl,
                    visible: _showPass,
                    onToggle: () => setState(() => _showPass = !_showPass),
                  ),
                  const SizedBox(height: 18),
                  _labeledPassword(
                    label: 'Confirm App Password',
                    hint: 'Enter confirm app password',
                    controller: _confirmCtrl,
                    visible: _showConfirm,
                    onToggle: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _savePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.setPassGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Password & Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _cancelAndLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cancelRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Cancel and Logout',
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

  Widget _labeledPassword({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              const CustomPaint(
                size: Size(26, 26),
                painter: LockBadgePainter(
                  shackleColor: AppColors.textMuted,
                  bodyColor: AppColors.textMuted,
                  keyholeColor: Colors.white,
                  outlineOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !visible,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: EyeTogglePainter(isClosed: !visible),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
