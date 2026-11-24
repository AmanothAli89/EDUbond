import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/user_role_model.dart';
import '../../shared/widgets/empty_state_view.dart';

class AdminTeachersScreen extends ConsumerStatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  ConsumerState<AdminTeachersScreen> createState() =>
      _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends ConsumerState<AdminTeachersScreen> {
  String _currentTab = 'teachers'; // 'teachers' or 'blocked'
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final Map<String, String> _names = {};

  bool _loading = true;
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
    final adminRepo = ref.read(adminRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    try {
      if (_currentTab == 'teachers') {
        final list = await adminRepo.getAllTeachers();
        for (final t in list) {
          authRepo.getUserNameByEmail(t.email).then((name) {
            if (mounted) setState(() => _names[t.email] = name);
          }).catchError((_) {});
        }
        if (!mounted) return;
        setState(() {
          _teachers = list;
          _loading = false;
        });
      } else {
        final list = await adminRepo.getBlockedTeachers();
        for (final b in list) {
          authRepo.getUserNameByEmail(b.email).then((name) {
            if (mounted) setState(() => _names[b.email] = name);
          }).catchError((_) {});
        }
        if (!mounted) return;
        setState(() {
          _blocked = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showEduSnackBar(context, 'Failed to load data: $e');
      }
    }
  }

  Future<void> _confirmRemoveTeacher(UserRoleModel teacher) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Teacher'),
        content: Text(
          'Are you sure you want to remove ${teacher.email} from teaching ${teacher.subject}?',
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
        await ref.read(adminRepositoryProvider).removeTeacherRole(
              email: teacher.email,
              subject: teacher.subject,
            );
        if (!mounted) return;
        showEduSnackBar(context, 'Teacher removed successfully');
        _loadData();
      } catch (_) {
        if (mounted) showEduSnackBar(context, 'Failed to remove teacher');
      }
    }
  }

  Future<void> _unblockTeacher(QuizAttemptModel attempt) async {
    try {
      await ref.read(adminRepositoryProvider).unblockTeacher(
            email: attempt.email,
            subject: attempt.subject,
          );
      if (!mounted) return;
      showEduSnackBar(context, 'User unblocked');
      _loadData();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to unblock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EduBackHeader(title: 'Manage Teachers'),
              Row(
                children: [
                  Expanded(
                    child: _tabBtn('Teachers', _currentTab == 'teachers', () {
                      if (_currentTab != 'teachers') {
                        setState(() => _currentTab = 'teachers');
                        _loadData();
                      }
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tabBtn('Blocked', _currentTab == 'blocked', () {
                      if (_currentTab != 'blocked') {
                        setState(() => _currentTab = 'blocked');
                        _loadData();
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              EduTextField(
                controller: _searchCtrl,
                hintText: _currentTab == 'teachers'
                    ? 'Search by email or subject...'
                    : 'Search blocked teachers...',
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentTab == 'teachers'
                        ? (filteredTeachers.isEmpty
                            ? EmptyStateView(
                                message: q.isEmpty
                                    ? 'No teachers found'
                                    : 'No matching teachers',
                              )
                            : ListView.builder(
                                itemCount: filteredTeachers.length,
                                itemBuilder: (_, i) {
                                  final t = filteredTeachers[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: EduCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            _names[t.email] ?? t.email,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            t.email,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Subject: ${t.subject}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.indigo,
                                            ),
                                          ),
                                          Text(
                                            'Quiz Score: ${t.score}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.emeraldBright,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _confirmRemoveTeacher(t),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.dangerRed,
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Remove Teacher Role',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ))
                        : (filteredBlocked.isEmpty
                            ? EmptyStateView(
                                message: q.isEmpty
                                    ? 'No blocked teachers'
                                    : 'No matching results',
                              )
                            : ListView.builder(
                                itemCount: filteredBlocked.length,
                                itemBuilder: (_, i) {
                                  final b = filteredBlocked[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: EduCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            _names[b.email] ?? b.email,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            b.email,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Blocked for Subject: ${b.subject}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.dangerRed,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _unblockTeacher(b),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.emeraldBright,
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Unblock User'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.indigo : AppColors.inputSurface,
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
}
