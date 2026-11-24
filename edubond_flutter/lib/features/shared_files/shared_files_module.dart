import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class SharedFilesModulePage extends StatelessWidget {
  const SharedFilesModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Shared Files',
      kotlinSource: 'SharedFilesActivity.kt',
      description:
          'Backed by ChatRepository: Filtered stream of shared files in a group with external viewer launch and uploader unsend.',
    );
  }
}
