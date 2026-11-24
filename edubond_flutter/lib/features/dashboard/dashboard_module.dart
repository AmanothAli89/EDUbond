import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';

class DashboardModulePage extends ConsumerStatefulWidget {
  const DashboardModulePage({super.key});

  @override
  ConsumerState<DashboardModulePage> createState() =>
      _DashboardModulePageState();
}

class _DashboardModulePageState extends ConsumerState<DashboardModulePage> {
  String _username = 'User';
  String _initials = 'US';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final repo = ref.read(authRepositoryProvider);
    final fbUser = repo.currentFirebaseUser;
    if (fbUser == null || (fbUser.email?.isEmpty ?? true)) {
      await repo.logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
      return;
    }

    final email = fbUser.email!;
    await ref.read(localStorageServiceProvider).setCurrentUser(email);
    final fallback = (fbUser.displayName?.isNotEmpty ?? false)
        ? fbUser.displayName!
        : email;

    var resolvedName = fallback;
    try {
      final profile = await repo.fetchUserProfile(fbUser.uid);
      if (profile != null && profile.username.isNotEmpty) {
        resolvedName = profile.username;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _username = resolvedName;
      _initials = resolvedName.trim().isNotEmpty
          ? resolvedName.trim().substring(0, resolvedName.trim().length >= 2 ? 2 : 1).toUpperCase()
          : 'US';
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'EduBond Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).pushNamed(AppRoutes.profile);
                        _loadUser();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.badgeBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      colors: [AppColors.deepBlue, AppColors.primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepBlue.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading ? 'Welcome, ...' : 'Welcome, $_username',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to learn together?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFBFDBFE),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. 2x2 Grid Menu
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
                          label: 'Search & Learn',
                          accentColor: AppColors.primaryBlue,
                          painter: const SearchIconPainter(),
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.subjects),
                        ),
                        DashboardGridTile(
                          label: 'Group Requests',
                          accentColor: AppColors.primaryPurple,
                          painter: const UsersIconPainter(),
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.requests),
                        ),
                        DashboardGridTile(
                          label: 'My Groups',
                          accentColor: AppColors.emerald,
                          painter: const ChatIconPainter(),
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.groups),
                        ),
                        DashboardGridTile(
                          label: 'Logout',
                          accentColor: AppColors.textSlate,
                          painter: const LogoutIconPainter(),
                          onTap: _confirmLogout,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
