import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import 'authentication_module.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showEduSnackBar(context, 'Could not open link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Developer Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/developer_pic.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.school,
                  size: 64,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppConstants.developerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppConstants.developerDegree,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppColors.textSlate),
          ),
          const SizedBox(height: 20),
          _infoRow(
            context,
            emoji: '📩',
            label: 'Email: ${AppConstants.developerEmail}',
            url: 'mailto:${AppConstants.developerEmail}',
          ),
          _infoRow(
            context,
            emoji: '💼',
            label: 'LinkedIn: md-lemon-islam-bappy',
            url: AppConstants.developerLinkedIn,
          ),
          _infoRow(
            context,
            emoji: '💻',
            label: 'GitHub: bappy-81',
            url: AppConstants.developerGitHub,
          ),
          const SizedBox(height: 20),
          AuthSolidButton(
            label: 'Back to Login',
            color: AppColors.deepPurple,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchLink(context, url),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.authBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.authBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
