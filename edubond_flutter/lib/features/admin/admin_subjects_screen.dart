import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../models/subject_request_model.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'admin_access_guard.dart';

class AdminSubjectsScreen extends ConsumerStatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  ConsumerState<AdminSubjectsScreen> createState() =>
      _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends ConsumerState<AdminSubjectsScreen> {
  String _currentTab = 'list'; // 'list' or 'requests'
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<String> _subjects = [];
  List<SubjectRequestModel> _requests = [];

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
    final repo = ref.read(subjectRepositoryProvider);
    try {
      if (_currentTab == 'list') {
        final list = await repo.getGlobalSubjects();
        if (!mounted) return;
        setState(() {
          _subjects = list;
          _loading = false;
        });
      } else {
        final reqs = await repo.getSubjectRequests();
        if (!mounted) return;
        setState(() {
          _requests = reqs;
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

  Future<void> _showAddSubjectDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _SubjectTextInputDialog(
        title: 'Add New Subject',
        hintText: 'Enter subject name',
        confirmLabel: 'Add',
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await ref.read(subjectRepositoryProvider).addSubjectGlobally(name);
        if (!mounted) return;
        showEduSnackBar(context, 'Subject added globally');
        _loadData();
      } catch (_) {
        if (mounted) showEduSnackBar(context, 'Failed to add subject');
      }
    }
  }

  Future<void> _confirmDeleteSubject(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(subjectRepositoryProvider).deleteSubjectGlobally(name);
        if (!mounted) return;
        showEduSnackBar(context, 'Deleted');
        _loadData();
      } catch (_) {
        if (mounted) showEduSnackBar(context, 'Delete failed');
      }
    }
  }

  Future<void> _acceptRequest(SubjectRequestModel req, {String? renamed}) async {
    final repo = ref.read(subjectRepositoryProvider);
    final finalName = renamed ?? req.subject;
    try {
      await repo.updateSubjectRequestStatus(
        requestId: req.id,
        status: 'accepted',
        updatedName: renamed,
      );
      await repo.addSubjectGlobally(finalName);
      if (!mounted) return;
      showEduSnackBar(context, 'Subject Accepted & Added Globally');
      _loadData();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to process request');
    }
  }

  Future<void> _rejectRequest(SubjectRequestModel req) async {
    try {
      await ref.read(subjectRepositoryProvider).updateSubjectRequestStatus(
            requestId: req.id,
            status: 'rejected',
          );
      if (!mounted) return;
      showEduSnackBar(context, 'Subject Rejected');
      _loadData();
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Failed to update status');
    }
  }

  Future<void> _showEditRequestDialog(SubjectRequestModel req) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _SubjectTextInputDialog(
        title: 'Edit & Accept Request',
        initialValue: req.subject,
        confirmLabel: 'Save & Accept',
      ),
    );
    if (updated != null && updated.isNotEmpty) {
      await _acceptRequest(req, renamed: updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filteredSubjects = _subjects
        .where((s) => q.isEmpty || s.toLowerCase().contains(q))
        .toList();
    final filteredRequests = _requests
        .where(
          (r) =>
              r.status == 'pending' &&
              (q.isEmpty || r.subject.toLowerCase().contains(q)),
        )
        .toList();

    return AdminAccessGuard(
      child: Scaffold(
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EduBackHeader(title: 'Manage Subjects'),
              Row(
                children: [
                  Expanded(
                    child: _tabBtn('Subject List', _currentTab == 'list', () {
                      if (_currentTab != 'list') {
                        setState(() => _currentTab = 'list');
                        _loadData();
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabBtn('Requests', _currentTab == 'requests', () {
                      if (_currentTab != 'requests') {
                        setState(() => _currentTab = 'requests');
                        _loadData();
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EduTextField(
                controller: _searchCtrl,
                hintText: 'Search subjects...',
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentTab == 'list'
                        ? _buildSubjectList(filteredSubjects)
                        : _buildRequestList(filteredRequests),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSubjectList(List<String> list) {
    return ListView(
      children: [
        EduButton(
          label: '+ Add New Subject',
          backgroundColor: AppColors.emeraldBright,
          height: 50,
          onPressed: _showAddSubjectDialog,
        ),
        const SizedBox(height: 18),
        ...list.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: EduCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Subject Status: Active',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _smallBtn(
                        'Questions',
                        const Color(0xFF3B82F6),
                        () => Navigator.of(context).pushNamed(
                          AppRoutes.adminQuiz,
                          arguments: name,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _smallBtn(
                        'Delete',
                        AppColors.dangerRed,
                        () => _confirmDeleteSubject(name),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList(List<SubjectRequestModel> reqs) {
    if (reqs.isEmpty) {
      return EmptyStateView(
        message: _searchQuery.isEmpty
            ? 'No pending requests'
            : 'No matching results',
      );
    }
    return ListView.builder(
      itemCount: reqs.length,
      itemBuilder: (_, i) {
        final r = reqs[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EduCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested by: ${r.by}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _smallBtn(
                        'Accept',
                        AppColors.emeraldBright,
                        () => _acceptRequest(r),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _smallBtn(
                        'Edit',
                        const Color(0xFF3B82F6),
                        () => _showEditRequestDialog(r),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _smallBtn(
                        'Reject',
                        AppColors.dangerRed,
                        () => _rejectRequest(r),
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

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B5CF6) : AppColors.inputSurface,
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

  Widget _smallBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(86, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SubjectTextInputDialog extends StatefulWidget {
  const _SubjectTextInputDialog({
    required this.title,
    required this.confirmLabel,
    this.hintText,
    this.initialValue = '',
  });

  final String title;
  final String confirmLabel;
  final String? hintText;
  final String initialValue;

  @override
  State<_SubjectTextInputDialog> createState() =>
      _SubjectTextInputDialogState();
}

class _SubjectTextInputDialogState extends State<_SubjectTextInputDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        decoration: widget.hintText != null
            ? InputDecoration(hintText: widget.hintText)
            : const InputDecoration(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
