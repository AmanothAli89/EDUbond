import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class RequestsModulePage extends StatelessWidget {
  const RequestsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Group & Teaching Requests',
      kotlinSource: 'RequestsActivity.kt',
      description:
          'Backed by GroupRepository: Incoming join requests, incoming teaching invitations, and sent request status tracker.',
    );
  }
}
