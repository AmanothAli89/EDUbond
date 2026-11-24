import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../models/group_model.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_banner.dart';

class GroupsModulePage extends ConsumerStatefulWidget {
  const GroupsModulePage({super.key});

  @override
  ConsumerState<GroupsModulePage> createState() => _GroupsModulePageState();
}

class _GroupsModulePageState extends ConsumerState<GroupsModulePage> {
  List<GroupModel> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = ref.read(authRepositoryProvider).currentLocalEmail;
    try {
      final list =
          await ref.read(groupRepositoryProvider).getGroupsForUser(email);
      if (!mounted) return;
      setState(() {
        _groups = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load groups: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadGroups,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'My Groups',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  ErrorBanner(message: _error!, onRetry: _loadGroups)
                else if (_groups.isEmpty)
                  const EmptyStateView(
                    message: "You haven't joined any groups yet.",
                    icon: Icons.forum_outlined,
                  )
                else
                  ..._groups.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.chat,
                            arguments: {
                              'groupId': group.id,
                              'groupName': group.name,
                            },
                          );
                          _loadGroups();
                        },
                        child: EduCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 22,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group.subject,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                EduButton(
                  label: 'BACK',
                  backgroundColor: AppColors.textBody,
                  borderRadius: 12,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
