import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../core/widgets/edu_text_field.dart';
import '../../shared/widgets/error_banner.dart';

class SubjectsModulePage extends ConsumerStatefulWidget {
  const SubjectsModulePage({super.key});

  @override
  ConsumerState<SubjectsModulePage> createState() => _SubjectsModulePageState();
}

class _SubjectsModulePageState extends ConsumerState<SubjectsModulePage> {
  final _searchCtrl = TextEditingController();
  List<String> _allSubjects = [];
  String _query = '';
  bool _isListVisible = true;
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
    try {
      final list = await ref.read(subjectRepositoryProvider).getGlobalSubjects();
      if (!mounted) return;
      setState(() {
        _allSubjects = list;
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

  Future<void> _requestNewSubject() async {
    final subjectName = _searchCtrl.text.trim();
    if (subjectName.isEmpty) {
      showEduSnackBar(
        context,
        'Please enter a subject name in the search box first.',
      );
      return;
    }

    final email = ref.read(authRepositoryProvider).currentLocalEmail;
    setState(() => _submitting = true);
    try {
      await ref.read(subjectRepositoryProvider).submitSubjectRequest(
            subjectName: subjectName,
            requesterEmail: email,
          );
      if (mounted) showEduSnackBar(context, 'Subject add request sent to admin');
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Failed to send request: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allSubjects
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                            arguments: subject.trim(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Center(
                              child: Text(
                                subject.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
