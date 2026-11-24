import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_card.dart';

/// Foundation entry screen verifying Firebase + LocalStorage wiring and
/// exposing navigation to the structured feature modules.
class SplashGatePage extends ConsumerWidget {
  const SplashGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final firebaseApps = Firebase.apps;
    final currentLocalUser = authRepo.currentLocalEmail;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.deepBlue, AppColors.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFBFDBFE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    EduCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phase 2 Foundation Status',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Firebase Initialized: ${firebaseApps.isNotEmpty}',
                            style: const TextStyle(color: AppColors.textBody),
                          ),
                          Text(
                            'Package ID: ${AppConstants.androidPackageId}',
                            style: const TextStyle(color: AppColors.textBody),
                          ),
                          Text(
                            'Local Session User: ${currentLocalUser.isEmpty ? "Signed out" : currentLocalUser}',
                            style: const TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _moduleChip(context, 'Authentication', AppRoutes.auth),
                        _moduleChip(context, 'Dashboard', AppRoutes.dashboard),
                        _moduleChip(context, 'Profile', AppRoutes.profile),
                        _moduleChip(context, 'Subjects', AppRoutes.subjects),
                        _moduleChip(context, 'Quiz', AppRoutes.quiz),
                        _moduleChip(context, 'Groups', AppRoutes.groups),
                        _moduleChip(context, 'Chat', AppRoutes.chat),
                        _moduleChip(context, 'Requests', AppRoutes.requests),
                        _moduleChip(context, 'Shared Files', AppRoutes.sharedFiles),
                        _moduleChip(context, 'Group Info', AppRoutes.groupInfo),
                        _moduleChip(context, 'Admin', AppRoutes.admin),
                        _moduleChip(context, 'Reports', AppRoutes.reports),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _moduleChip(BuildContext context, String label, String route) {
    return ActionChip(
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}
