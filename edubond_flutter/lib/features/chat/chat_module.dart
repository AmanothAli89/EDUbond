import 'package:material_ui/material_ui.dart';
import '../../shared/widgets/feature_foundation_page.dart';

class ChatModulePage extends StatelessWidget {
  const ChatModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureFoundationPage(
      moduleName: 'Group Chat Room',
      kotlinSource: 'GroupRoomActivity.kt',
      description:
          'Backed by ChatRepository: Real-time Firestore message stream, seenBy read receipts, unsend, catbox.moe file sharing, and meeting links.',
    );
  }
}
