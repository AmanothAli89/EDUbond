import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../models/group_request_model.dart';
import '../../shared/widgets/error_banner.dart';

class RequestsModulePage extends ConsumerStatefulWidget {
  const RequestsModulePage({super.key});

  @override
  ConsumerState<RequestsModulePage> createState() => _RequestsModulePageState();
}

class _RequestsModulePageState extends ConsumerState<RequestsModulePage> {
  List<GroupRequestModel> _joinRequests = [];
  List<GroupRequestModel> _teacherRequests = [];
  List<GroupRequestModel> _sentRequests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = ref.read(authRepositoryProvider).currentLocalEmail;
    final repo = ref.read(groupRepositoryProvider);

    try {
      final results = await Future.wait([
        repo.getIncomingJoinRequests(email),
        repo.getIncomingTeacherRequests(email),
        repo.getSentRequests(email),
      ]);
      if (!mounted) return;
      setState(() {
        _joinRequests = results[0];
        _teacherRequests = results[1];
        _sentRequests = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load requests: $e';
        _loading = false;
      });
    }
  }

  Future<void> _acceptJoin(GroupRequestModel req) async {
    try {
      await ref.read(groupRepositoryProvider).acceptJoinRequest(
            requestId: req.id,
            groupId: req.groupId,
            requesterEmail: req.requester,
          );
      if (!mounted) return;
      showEduSnackBar(context, 'Approved Successfully');
      _loadRequests();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to approve');
    }
  }

  Future<void> _rejectJoin(GroupRequestModel req) async {
    try {
      await ref.read(groupRepositoryProvider).rejectJoinRequest(req.id);
      if (!mounted) return;
      showEduSnackBar(context, 'Rejected Successfully');
      _loadRequests();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to reject');
    }
  }

  Future<void> _acceptTeaching(GroupRequestModel req) async {
    final email = ref.read(authRepositoryProvider).currentLocalEmail;
    try {
      await ref.read(groupRepositoryProvider).acceptTeacherRequest(
            requestId: req.id,
            groupId: req.groupId,
            teacherEmail: email,
          );
      if (!mounted) return;
      showEduSnackBar(context, 'Accepted Successfully');
      _loadRequests();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to accept');
    }
  }

  Future<void> _rejectTeaching(GroupRequestModel req) async {
    try {
      await ref.read(groupRepositoryProvider).rejectTeacherRequest(req.id);
      if (!mounted) return;
      showEduSnackBar(context, 'Rejected Successfully');
      _loadRequests();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to reject');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRequests,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EduBackHeader(title: 'Requests', fontSize: 26),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  ErrorBanner(message: _error!, onRetry: _loadRequests)
                else ...[
                  _sectionTitle('Join Requests'),
                  if (_joinRequests.isEmpty)
                    _emptyText('No pending join requests.')
                  else
                    ..._joinRequests.map(
                      (req) => _actionRequestCard(
                        lines: [
                          'Requester: ${req.requester}',
                          'Group: ${req.groupName}',
                        ],
                        positiveLabel: 'Approve',
                        onPositive: () => _acceptJoin(req),
                        onNegative: () => _rejectJoin(req),
                      ),
                    ),
                  _sectionTitle('Teaching Requests'),
                  if (_teacherRequests.isEmpty)
                    _emptyText('No pending teaching requests.')
                  else
                    ..._teacherRequests.map(
                      (req) => _actionRequestCard(
                        lines: [
                          'Group: ${req.groupName}',
                          'Subject: ${req.subject}',
                        ],
                        positiveLabel: 'Accept',
                        onPositive: () => _acceptTeaching(req),
                        onNegative: () => _rejectTeaching(req),
                      ),
                    ),
                  _sectionTitle('My Sent Requests'),
                  if (_sentRequests.isEmpty)
                    _emptyText("You haven't sent any requests.")
                  else
                    ..._sentRequests.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: EduCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join: ${req.groupName}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${req.status}',
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textSlate,
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: AppColors.textSubtle),
      ),
    );
  }

  Widget _actionRequestCard({
    required List<String> lines,
    required String positiveLabel,
    required VoidCallback onPositive,
    required VoidCallback onNegative,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: EduCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onPositive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldBright,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(positiveLabel),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: onNegative,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
