import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role_model.dart';
import '../../shared/widgets/empty_state_view.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _currentTab = 'users'; // 'users' or 'teachers'
  String _teacherSubTab = 'active'; // 'active' or 'blocked'
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<UserModel> _users = [];
  List<UserRoleModel> _teachers = [];
  List<QuizAttemptModel> _blocked = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (_currentTab == 'users') {
        final users = await repo.getAllUsers();
        if (!mounted) return;
        setState(() {
          _users = users;
          _loading = false;
        });
      } else if (_teacherSubTab == 'active') {
        final teachers = await repo.getAllTeachers();
        if (!mounted) return;
        setState(() {
          _teachers = teachers;
          _loading = false;
        });
      } else {
        final blocked = await repo.getBlockedTeachers();
        if (!mounted) return;
        setState(() {
          _blocked = blocked;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showEduSnackBar(context, 'Error: $e');
      }
    }
  }

  Future<void> _showAddRoleDialog(String email) async {
    try {
      final subjects =
          await ref.read(subjectRepositoryProvider).getGlobalSubjects();
      if (!mounted) return;
      if (subjects.isEmpty) {
        showEduSnackBar(context, 'No subjects found. Please add subjects first.');
        return;
      }

      var selected = subjects.first;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Assign Teaching Role'),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) {
                  if (v != null) setDialogState(() => selected = v);
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subjects.length,
                  itemBuilder: (_, idx) {
                    final sub = subjects[idx];
                    return RadioListTile<String>(
                      value: sub,
                      title: Text(sub),
                      dense: true,
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true) {
        await ref.read(adminRepositoryProvider).assignTeacherRole(
              email: email,
              subject: selected,
            );
        if (mounted) {
          showEduSnackBar(context, 'Assigned $email to $selected');
          if (_currentTab == 'teachers') _loadData();
        }
      }
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _confirmRemoveUser(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove User'),
        content: Text(
          'Are you sure you want to remove ${user.email} from the database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(adminRepositoryProvider).removeUserDocument(user.uid);
        if (!mounted) return;
        showEduSnackBar(context, 'User removed');
        _loadData();
      } catch (e) {
        if (mounted) showEduSnackBar(context, 'Failed: $e');
      }
    }
  }

  Future<void> _confirmRemoveTeacherRole(UserRoleModel role) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Role'),
        content: Text('Remove ${role.email} from teaching ${role.subject}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .removeTeacherRoleByDocId(role.docId);
        if (!mounted) return;
        showEduSnackBar(context, 'Role removed');
        _loadData();
      } catch (e) {
        if (mounted) showEduSnackBar(context, 'Failed: $e');
      }
    }
  }

  Future<void> _unblock(QuizAttemptModel attempt) async {
    try {
      await ref.read(adminRepositoryProvider).unblockTeacher(
            email: attempt.email,
            subject: attempt.subject,
          );
      if (!mounted) return;
      showEduSnackBar(context, 'User unblocked');
      _loadData();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Unblock failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filteredUsers = _users
        .where(
          (u) =>
              q.isEmpty ||
              u.username.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
    final filteredTeachers = _teachers
        .where(
          (t) =>
              q.isEmpty ||
              t.email.toLowerCase().contains(q) ||
              t.subject.toLowerCase().contains(q),
        )
        .toList();
    final filteredBlocked = _blocked
        .where(
          (b) =>
              q.isEmpty ||
              b.email.toLowerCase().contains(q) ||
              b.subject.toLowerCase().contains(q),
        )
        .toList();

    final countLabel = _loading
        ? 'Fetching...'
        : _currentTab == 'users'
            ? 'Showing ${filteredUsers.length} users'
            : _teacherSubTab == 'active'
                ? 'Showing ${filteredTeachers.length} active teachers'
                : 'Showing ${filteredBlocked.length} blocked teachers';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EduBackHeader(title: 'User Management'),
              Row(
                children: [
                  Expanded(
                    child: _tabBtn(
                      'All Users',
                      _currentTab == 'users',
                      () {
                        if (_currentTab != 'users') {
                          setState(() => _currentTab = 'users');
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tabBtn(
                      'Teachers',
                      _currentTab == 'teachers',
                      () {
                        if (_currentTab != 'teachers') {
                          setState(() => _currentTab = 'teachers');
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_currentTab == 'teachers') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _subTabBtn(
                        'Active Teachers',
                        _teacherSubTab == 'active',
                        () {
                          if (_teacherSubTab != 'active') {
                            setState(() => _teacherSubTab = 'active');
                            _loadData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _subTabBtn(
                        'Blocked Teachers',
                        _teacherSubTab == 'blocked',
                        () {
                          if (_teacherSubTab != 'blocked') {
                            setState(() => _teacherSubTab = 'blocked');
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              EduTextField(
                controller: _searchCtrl,
                hintText: _currentTab == 'users'
                    ? 'Search users...'
                    : (_teacherSubTab == 'active'
                        ? 'Search active teachers...'
                        : 'Search blocked teachers...'),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 10),
              Text(
                countLabel,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentTab == 'users'
                        ? _buildUsersList(filteredUsers)
                        : (_teacherSubTab == 'active'
                            ? _buildTeachersList(filteredTeachers)
                            : _buildBlockedList(filteredBlocked)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    if (users.isEmpty) {
      return EmptyStateView(
        message: _searchQuery.isEmpty ? 'No users found' : 'No matching users',
      );
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, idx) {
        final u = users[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EduCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.username.isEmpty ? 'Unknown' : u.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  u.email.isEmpty ? 'No Email' : u.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _smallActionBtn(
                        'Add Role',
                        AppColors.emeraldBright,
                        () => _showAddRoleDialog(u.email),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _smallActionBtn(
                        'Remove',
                        AppColors.dangerRed,
                        () => _confirmRemoveUser(u),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeachersList(List<UserRoleModel> roles) {
    if (roles.isEmpty) {
      return EmptyStateView(
        message: _searchQuery.isEmpty
            ? 'No active teachers'
            : 'No matching results',
      );
    }
    return ListView.builder(
      itemCount: roles.length,
      itemBuilder: (_, idx) {
        final r = roles[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EduCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  r.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teacher: ${r.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified Score: ${r.score}/10',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 12),
                _smallActionBtn(
                  'Remove Teaching Role',
                  AppColors.dangerRed,
                  () => _confirmRemoveTeacherRole(r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedList(List<QuizAttemptModel> blocked) {
    if (blocked.isEmpty) {
      return EmptyStateView(
        message: _searchQuery.isEmpty
            ? 'No blocked teachers'
            : 'No matching results',
      );
    }
    return ListView.builder(
      itemCount: blocked.length,
      itemBuilder: (_, idx) {
        final b = blocked[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EduCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  b.email,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blocked from: ${b.subject}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.dangerRed,
                  ),
                ),
                const SizedBox(height: 12),
                _smallActionBtn(
                  'Unblock User',
                  AppColors.emeraldBright,
                  () => _unblock(b),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _subTabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppColors.softIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: AppColors.indigo) : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.indigo : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallActionBtn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
