import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _visible = false;
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    final id = _idCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (id.isEmpty || pass.isEmpty) {
      showEduSnackBar(context, 'Please enter credentials');
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await ref
          .read(authRepositoryProvider)
          .loginAsAdmin(adminId: id, password: pass);
      if (!mounted) return;
      if (ok) {
        showEduSnackBar(context, 'Admin login successful.');
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.admin, (_) => false);
      } else {
        showEduSnackBar(context, 'Wrong Admin ID or password.');
      }
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Admin login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF2E7FF), Color(0xFFF7F0FF)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.adminPurple
                                    .withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CustomPaint(
                              size: Size(52, 52),
                              painter: AdminShieldPainter(
                                color: AppColors.adminPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.adminPurple,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                AppConstants.appTagline,
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
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFEEF2F7)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Admin Login',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _adminField(
                            controller: _idCtrl,
                            hint: 'Admin ID',
                            prefix: const CustomPaint(
                              size: Size(28, 28),
                              painter: UserOutlinePainter(
                                color: AppColors.textGrayIcon,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _adminField(
                            controller: _passCtrl,
                            hint: 'Admin Password',
                            obscureText: !_visible,
                            prefix: const CustomPaint(
                              size: Size(28, 28),
                              painter: LockBadgePainter(
                                shackleColor: AppColors.textGrayIcon,
                                bodyColor: AppColors.textGrayIcon,
                                keyholeColor: Colors.white,
                                outlineOnly: true,
                              ),
                            ),
                            suffix: GestureDetector(
                              onTap: () =>
                                  setState(() => _visible = !_visible),
                              child: CustomPaint(
                                size: const Size(24, 24),
                                painter: EyeTogglePainter(isClosed: !_visible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.adminPurple,
                                  AppColors.adminPurpleLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.adminPurple
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _loginAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login as Admin',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mutedGrayBtn,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminField({
    required TextEditingController controller,
    required String hint,
    required Widget prefix,
    Widget? suffix,
    bool obscureText = false,
  }) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          prefix,
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
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
