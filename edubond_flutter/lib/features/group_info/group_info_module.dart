import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../models/group_model.dart';

class GroupInfoModulePage extends ConsumerStatefulWidget {
  const GroupInfoModulePage({super.key, this.groupId = ''});

  final String groupId;

  @override
  ConsumerState<GroupInfoModulePage> createState() =>
      _GroupInfoModulePageState();
}

class _GroupInfoModulePageState extends ConsumerState<GroupInfoModulePage> {
  GroupModel? _group;
  List<String> _availableTeachers = [];
  final Map<String, String> _names = {};
  final Set<String> _requestedTeachers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.groupId.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final group =
          await ref.read(groupRepositoryProvider).getGroupInfo(widget.groupId);
      if (!mounted) return;
      if (group == null) {
        Navigator.of(context).pop();
        return;
      }

      final qualified = await ref
          .read(subjectRepositoryProvider)
          .getQualifiedTeachers(group.subject);
      final filtered =
          qualified.where((t) => !group.teachers.contains(t)).toList();

      final allEmails = {...group.teachers, ...group.members, ...filtered};
      final authRepo = ref.read(authRepositoryProvider);
      for (final email in allEmails) {
        authRepo.getUserNameByEmail(email).then((name) {
          if (mounted) setState(() => _names[email] = name);
        }).catchError((_) {});
      }

      if (!mounted) return;
      setState(() {
        _group = group;
        _availableTeachers = filtered;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestTeacher(String teacherEmail) async {
    final group = _group;
    if (group == null) return;
    final currentUser = ref.read(authRepositoryProvider).currentLocalEmail;

    try {
      await ref.read(groupRepositoryProvider).requestTeacherToJoin(
            groupId: group.id,
            groupName: group.name,
            subject: group.subject,
            requesterEmail: currentUser,
            teacherEmail: teacherEmail,
          );
      if (!mounted) return;
      setState(() => _requestedTeachers.add(teacherEmail));
      showEduSnackBar(context, 'Request sent to teacher');
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to send request');
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final email = ref.read(authRepositoryProvider).currentLocalEmail;
    try {
      await ref
          .read(groupRepositoryProvider)
          .leaveGroup(groupId: widget.groupId, email: email);
      if (!mounted) return;
      showEduSnackBar(context, 'You left the group');
      Navigator.of(context).popUntil(
        (route) =>
            route.settings.name == AppRoutes.groups ||
            route.settings.name == AppRoutes.dashboard ||
            route.isFirst,
      );
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to leave group');
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;

    return Scaffold(
      body: SafeArea(
        child: _loading || group == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EduBackHeader(title: group.name, fontSize: 25),
                    EduCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        children: [
                          _infoRow('Subject:', group.subject),
                          const SizedBox(height: 8),
                          _infoRow('Creator:', group.createdBy),
                        ],
                      ),
                    ),
                    _sectionTitle('Teachers'),
                    if (group.teachers.isEmpty)
                      _emptyText('No teachers added yet.')
                    else
                      ...group.teachers.map(_memberCard),
                    _sectionTitle('Members'),
                    if (group.members.isEmpty)
                      _emptyText('No members found.')
                    else
                      ...group.members.map(_memberCard),
                    _sectionTitle('Hire Qualified Teachers'),
                    if (_availableTeachers.isEmpty)
                      _emptyText(
                        'No other qualified teachers available for this subject.',
                      )
                    else
                      ..._availableTeachers.map((teacherEmail) {
                        final sent = _requestedTeachers.contains(teacherEmail);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EduCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            borderRadius: 20,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _names[teacherEmail] ?? teacherEmail,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        teacherEmail,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: sent
                                      ? null
                                      : () => _requestTeacher(teacherEmail),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(90, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(sent ? 'Sent' : 'Request'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 28),
                    EduButton(
                      label: '📁 View Shared Files',
                      backgroundColor: const Color(0xFF3B82F6),
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.sharedFiles,
                        arguments: widget.groupId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EduButton(
                      label: 'Leave Group',
                      backgroundColor: AppColors.dangerRed,
                      onPressed: _confirmLeaveGroup,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: AppColors.textSubtle),
      ),
    );
  }

  Widget _memberCard(String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _names[email] ?? email,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              email,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
