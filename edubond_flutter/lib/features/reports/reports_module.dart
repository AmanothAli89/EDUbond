import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class ReportsModulePage extends StatelessWidget {
  const ReportsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'System Reports',
      kotlinSource: 'AdminReportsActivity.kt',
      description:
          'Backed by AdminRepository & fl_chart: Total user statistics and 7-day weekly bar charts for New Users, New Groups, and New Teachers.',
    );
  }
}
