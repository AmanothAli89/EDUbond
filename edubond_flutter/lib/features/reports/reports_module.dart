import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../data/repositories/admin_repository.dart';
import '../../shared/widgets/error_banner.dart';

class ReportsModulePage extends ConsumerStatefulWidget {
  const ReportsModulePage({super.key});

  @override
  ConsumerState<ReportsModulePage> createState() => _ReportsModulePageState();
}

class _ReportsModulePageState extends ConsumerState<ReportsModulePage> {
  bool _loading = true;
  String? _error;
  WeeklyReportsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary =
          await ref.read(adminRepositoryProvider).fetchWeeklyReports();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load reports: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EduBackHeader(title: 'System Reports'),
                EduCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Users',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary == null ? '0' : summary.totalUsers.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ErrorBanner(message: _error!, onRetry: _loadReports),
                  )
                else if (summary != null) ...[
                  _WeeklyChartSection(
                    title: 'New Users (Weekly)',
                    data: summary.newUsersWeekly,
                    barColor: const Color(0xFF3B82F6),
                  ),
                  _WeeklyChartSection(
                    title: 'New Groups (Weekly)',
                    data: summary.newGroupsWeekly,
                    barColor: AppColors.emeraldBright,
                  ),
                  _WeeklyChartSection(
                    title: 'New Teachers (Weekly)',
                    data: summary.newTeachersWeekly,
                    barColor: const Color(0xFF8B5CF6),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyChartSection extends StatelessWidget {
  const _WeeklyChartSection({
    required this.title,
    required this.data,
    required this.barColor,
  });

  final String title;
  final Map<String, int> data;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final days = DateFormatter.lastSevenDayLabels();
    final maxVal = data.values.fold<int>(
      5,
      (prev, el) => el > prev ? el : prev,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 24),
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
          const SizedBox(height: 12),
          EduCard(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxVal.toDouble(),
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final count = data[days[i]] ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSubtle,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[i],
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(days.length, (i) {
                    final count = (data[days[i]] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          color: barColor,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
