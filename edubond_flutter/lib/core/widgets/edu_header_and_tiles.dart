import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

class EduBackHeader extends StatelessWidget {
  const EduBackHeader({
    super.key,
    required this.title,
    this.onBack,
    this.fontSize = 24,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final double fontSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 14, top: 4, bottom: 4),
              child: Text(
                '←',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class DashboardGridTile extends StatelessWidget {
  const DashboardGridTile({
    super.key,
    required this.label,
    required this.accentColor,
    required this.painter,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final CustomPainter painter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: AppColors.textDark.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(32, 32),
                    painter: painter,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showEduSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
