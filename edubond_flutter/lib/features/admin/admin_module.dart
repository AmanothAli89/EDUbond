import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import 'admin_access_guard.dart';

class AdminModulePage extends ConsumerWidget {
  const AdminModulePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authRepositoryProvider).logout();
      if (!context.mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAccessGuard(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Row
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(26, 26),
                          painter: AdminShieldPainter(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Hero Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.adminHeroStart, AppColors.adminHeroEnd],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.adminHeroStart.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Admin',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'System overview and management',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE0E7FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Grid Menu
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 650 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.96,
                      children: [
                        DashboardGridTile(
                          label: 'Manage Users',
                          accentColor: const Color(0xFF3B82F6),
                          painter: const UserOutlinePainter(
                            color: Color(0xFF3B82F6),
                          ),
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.adminUsers),
                        ),
                        DashboardGridTile(
                          label: 'Subjects',
                          accentColor: const Color(0xFF8B5CF6),
                          painter: const StudyOptionIconPainter(
                            color: Color(0xFF8B5CF6),
                          ),
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.adminSubjects),
                        ),
                        DashboardGridTile(
                          label: 'Reports',
                          accentColor: AppColors.emeraldBright,
                          painter: const ReportIconPainter(),
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.reports),
                        ),
                        DashboardGridTile(
                          label: 'Logout',
                          accentColor: AppColors.textSlate,
                          painter: const LogoutIconPainter(),
                          onTap: () => _confirmLogout(context, ref),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminTeachers),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Dedicated Teachers Directory'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
