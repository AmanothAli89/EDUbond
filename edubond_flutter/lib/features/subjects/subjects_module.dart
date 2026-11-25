import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../models/subject_model.dart';
import '../../models/subject_request_model.dart';
import '../../shared/widgets/error_banner.dart';

class SubjectsModulePage extends ConsumerStatefulWidget {
  const SubjectsModulePage({super.key});

  @override
  ConsumerState<SubjectsModulePage> createState() => _SubjectsModulePageState();
}

class _SubjectsModulePageState extends ConsumerState<SubjectsModulePage> {
  final _searchCtrl = TextEditingController();
  List<SubjectModel> _allSubjects = [];
  List<SubjectRequestModel> _myRequests = [];
  String _query = '';
  bool _isListVisible = true;
  bool _isRequestsVisible = true;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(subjectRepositoryProvider);
    final email = ref.read(authRepositoryProvider).activeUserEmail;

    try {
      final list = await repo.getGlobalSubjectItems();
      var reqs = <SubjectRequestModel>[];
      try {
        reqs = await repo.getUserSubjectRequests(email);
      } catch (_) {
        // Keep subject list usable even if user request history fails to load.
      }
      if (!mounted) return;
      setState(() {
        _allSubjects = list;
        _myRequests = reqs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load subjects: $e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshRequestsOnly() async {
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    try {
      final reqs =
          await ref.read(subjectRepositoryProvider).getUserSubjectRequests(email);
      if (mounted) {
        setState(() => _myRequests = reqs);
      }
    } catch (_) {}
  }

  Future<void> _requestNewSubject() async {
    final subjectName = _searchCtrl.text.trim();
    if (subjectName.isEmpty) {
      showEduSnackBar(
        context,
        'Please enter a subject name in the search box first.',
      );
      return;
    }

    final email = ref.read(authRepositoryProvider).activeUserEmail;
    setState(() => _submitting = true);
    try {
      await ref.read(subjectRepositoryProvider).submitSubjectRequest(
            subjectName: subjectName,
            requesterEmail: email,
          );
      await _refreshRequestsOnly();
      if (mounted) {
        setState(() => _isRequestsVisible = true);
        showEduSnackBar(context, 'Subject add request sent to admin');
      }
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Failed to send request: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.softMint;
      case 'rejected':
        return AppColors.timerBg;
      default:
        return AppColors.softBlue;
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.emerald;
      case 'rejected':
        return AppColors.dangerRed;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qLower = _query.toLowerCase();
    final filtered = _allSubjects
        .where((s) => s.name.toLowerCase().contains(qLower))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSubjects,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Subject Search',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),

                // Search Section Card
                EduCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      EduTextField(
                        controller: _searchCtrl,
                        hintText: 'Search subject, e.g. Data S',
                        onChanged: (value) {
                          setState(() {
                            _query = value.trim();
                            if (_query.isNotEmpty) {
                              _isListVisible = true;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      EduButton(
                        label: 'REQUEST NEW SUBJECT ADD',
                        backgroundColor: AppColors.tealGreen,
                        borderRadius: 12,
                        height: 50,
                        isLoading: _submitting,
                        onPressed: _requestNewSubject,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Collapsible List Header
                InkWell(
                  onTap: () => setState(() => _isListVisible = !_isListVisible),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          'Subject List:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSlate,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isListVisible ? '(Click to hide)' : '(Click to show)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  ErrorBanner(message: _error!, onRetry: _loadSubjects)
                else if (_isListVisible) ...[
                  if (filtered.isEmpty && _query.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 14, left: 6),
                      child: Text(
                        'No matching subjects found.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (subject) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.subjectDetail,
                              arguments: subject.name.trim(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject.name.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subject.isAdmin
                                          ? AppColors.softIndigo
                                          : AppColors.softBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      subject.isAdmin ? 'Admin' : 'Core',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: subject.isAdmin
                                            ? AppColors.primaryPurple
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],

                if (!_loading && _myRequests.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () =>
                        setState(() => _isRequestsVisible = !_isRequestsVisible),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'My Subject Requests:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSlate,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isRequestsVisible
                                ? '(Click to hide)'
                                : '(Click to show)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isRequestsVisible)
                    ..._myRequests.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EduCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  req.subject,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(req.status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  req.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusFg(req.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 28),
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
