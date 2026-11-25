import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../models/group_model.dart';
import '../../shared/widgets/empty_state_view.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({super.key, required this.subject});

  final String subject;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  bool _showGroups = false;
  bool _busy = false;
  bool _loadingGroups = false;
  List<GroupModel> _groups = [];
  final Set<String> _pendingJoinGroupIds = {};
  final Set<String> _sendingRequestGroupIds = {};
  final _groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStudy() async {
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    if (email.isEmpty) {
      showEduSnackBar(context, 'Please sign in again.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(subjectRepositoryProvider).addSubjectRole(
            email: email,
            subject: widget.subject,
            role: 'learner',
          );
      if (!mounted) return;
      showEduSnackBar(context, 'You are now a learner for ${widget.subject}');
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to update status');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _showGroups = true;
        });
        _loadGroups();
      }
    }
  }

  Future<void> _selectTeach() async {
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    if (email.isEmpty) {
      showEduSnackBar(context, 'Please sign in again.');
      return;
    }

    setState(() => _busy = true);
    try {
      final roles =
          await ref.read(subjectRepositoryProvider).getUserSubjectRoles(email);
      final alreadyTeacher = roles.any(
        (r) => r.subject == widget.subject && r.isTeacher,
      );
      if (!mounted) return;
      if (alreadyTeacher) {
        showEduSnackBar(
          context,
          'You are already a teacher for ${widget.subject}',
        );
        return;
      }

      final attempt = await ref.read(quizRepositoryProvider).getQuizStatus(
            email: email,
            subject: widget.subject,
          );
      if (!mounted) return;
      if (attempt?.blocked == true ||
          (attempt?.attempts ?? 0) >= AppConstants.quizMaxAttempts) {
        showEduSnackBar(
          context,
          'You are blocked from teaching ${widget.subject} due to previous failed attempts.',
        );
        return;
      }

      Navigator.of(context).pushNamed(
        AppRoutes.quiz,
        arguments: widget.subject,
      );
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Error checking status: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadGroups() async {
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    setState(() => _loadingGroups = true);
    try {
      final groupRepo = ref.read(groupRepositoryProvider);
      final list = await groupRepo.getGroupsBySubject(widget.subject);
      final pendingIds = <String>{};
      if (email.isNotEmpty) {
        try {
          final sent = await groupRepo.getSentRequests(email);
          for (final req in sent) {
            if (req.status == 'pending' && req.groupId.isNotEmpty) {
              pendingIds.add(req.groupId);
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _groups = list;
        _pendingJoinGroupIds
          ..clear()
          ..addAll(pendingIds);
        _loadingGroups = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty) {
      showEduSnackBar(context, 'Please enter a group name');
      return;
    }
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    setState(() => _busy = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            subject: widget.subject,
            creatorEmail: email,
            groupName: name,
          );
      if (!mounted) return;
      _groupNameCtrl.clear();
      showEduSnackBar(context, 'Group created!');
      await _loadGroups();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to create group');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestJoin(GroupModel group, String email) async {
    if (_sendingRequestGroupIds.contains(group.id)) return;
    setState(() => _sendingRequestGroupIds.add(group.id));
    try {
      final created = await ref.read(groupRepositoryProvider).requestToJoinGroup(
            groupId: group.id,
            groupName: group.name,
            subject: widget.subject,
            requesterEmail: email,
          );
      if (!mounted) return;
      setState(() => _pendingJoinGroupIds.add(group.id));
      showEduSnackBar(
        context,
        created ? 'Request sent!' : 'Request already pending.',
      );
    } catch (_) {
      if (mounted) {
        showEduSnackBar(context, 'Failed to send request');
      }
    } finally {
      if (mounted) setState(() => _sendingRequestGroupIds.remove(group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showGroups,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showGroups) {
          setState(() => _showGroups = false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: _showGroups ? _buildGroupsView() : _buildRoleSelectionView(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EduBackHeader(title: widget.subject),
        const Text(
          'Select your role for this subject:',
          style: TextStyle(fontSize: 16, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        _optionCard(
          title: 'I want to study this',
          subtitle: 'Join groups and learn from others',
          accent: AppColors.primaryBlue,
          painter: const StudyOptionIconPainter(),
          onTap: _busy ? null : _selectStudy,
        ),
        const SizedBox(height: 18),
        _optionCard(
          title: 'I want to teach this',
          subtitle: 'Share your knowledge and mentor peers',
          accent: AppColors.primaryPurple,
          painter: const UserOutlinePainter(
            color: AppColors.primaryPurple,
            strokeWidth: 2.8,
          ),
          onTap: _busy ? null : _selectTeach,
        ),
      ],
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required Color accent,
    required CustomPainter painter,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: AppColors.textDark.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomPaint(size: const Size(30, 30), painter: painter),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '→',
                style: TextStyle(fontSize: 20, color: AppColors.borderSlate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsView() {
    final email = ref.read(authRepositoryProvider).activeUserEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EduBackHeader(
          title: widget.subject,
          onBack: () => setState(() => _showGroups = false),
        ),
        EduCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Start a Study Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              EduTextField(
                controller: _groupNameCtrl,
                hintText: 'Enter Group Name',
              ),
              const SizedBox(height: 14),
              EduButton(
                label: 'Create Group',
                backgroundColor: AppColors.primaryBlue,
                borderRadius: 12,
                height: 50,
                isLoading: _busy,
                onPressed: _createGroup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Available Groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textSlate,
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingGroups)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_groups.isEmpty)
          const EmptyStateView(
            message: 'No groups available for this subject yet.',
          )
        else
          ..._groups.map((group) {
            final inGroup = group.containsUser(email);
            final isPending = _pendingJoinGroupIds.contains(group.id);
            final isSending = _sendingRequestGroupIds.contains(group.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: EduCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Members: ${group.members.length}  •  Teachers: ${group.teachers.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: isSending || (!inGroup && isPending)
                          ? null
                          : () {
                              if (inGroup) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chat,
                                  arguments: {
                                    'groupId': group.id,
                                    'groupName': group.name,
                                  },
                                );
                              } else {
                                _requestJoin(group, email);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            inGroup ? AppColors.emerald : AppColors.softBlue,
                        foregroundColor:
                            inGroup ? Colors.white : AppColors.primaryBlue,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        inGroup
                            ? 'Open Group'
                            : (isPending ? 'Request Pending' : 'Request to Join'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
