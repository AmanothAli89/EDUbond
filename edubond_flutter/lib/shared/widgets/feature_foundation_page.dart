import 'package:material_ui/material_ui.dart';
import '../../core/constants/app_colors.dart';

/// Shared foundation scaffold for feature modules scheduled for Phase 3+ UI.
class FeatureFoundationPage extends StatelessWidget {
  const FeatureFoundationPage({
    super.key,
    required this.moduleName,
    required this.kotlinSource,
    required this.description,
  });

  final String moduleName;
  final String kotlinSource;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kotlin Source: $kotlinSource',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
