import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';

/// Route-level authorization gate preventing direct route navigation into
/// Admin screens without an authenticated admin session.
class AdminAccessGuard extends ConsumerWidget {
  const AdminAccessGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorized = ref.read(authRepositoryProvider).isAdminAuthorized;
    if (authorized) return child;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EduCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: AppColors.dangerRed,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unauthorized Access',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin authentication is required to access this section.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  EduButton(
                    label: 'Go to Admin Login',
                    backgroundColor: AppColors.adminPurple,
                    borderRadius: 12,
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.adminLogin,
                      (_) => false,
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
