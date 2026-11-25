import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_viewer_helper.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../models/message_model.dart';
import '../../shared/widgets/empty_state_view.dart';

class SharedFilesModulePage extends ConsumerStatefulWidget {
  const SharedFilesModulePage({super.key, this.groupId = ''});

  final String groupId;

  @override
  ConsumerState<SharedFilesModulePage> createState() =>
      _SharedFilesModulePageState();
}

class _SharedFilesModulePageState extends ConsumerState<SharedFilesModulePage> {
  final Map<String, String> _names = {};

  String _resolveName(String email) {
    final existing = _names[email];
    if (existing != null) return existing;
    _names[email] = email;
    ref.read(authRepositoryProvider).getUserNameByEmail(email).then((name) {
      if (mounted && _names[email] != name) {
        setState(() => _names[email] = name);
      }
    }).catchError((_) {});
    return email;
  }

  Future<void> _confirmUnsend(MessageModel msg) async {
    if (msg.id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Do you want to unsend this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unsend'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(chatRepositoryProvider).deleteMessage(
              groupId: widget.groupId,
              messageId: msg.id,
            );
      } catch (_) {
        if (mounted) showEduSnackBar(context, 'Failed to unsend');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(authRepositoryProvider).activeUserEmail;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EduBackHeader(title: 'Shared Files', fontSize: 22),
              Expanded(
                child: widget.groupId.isEmpty
                    ? const EmptyStateView(message: 'No group selected')
                    : StreamBuilder<List<MessageModel>>(
                        stream: ref
                            .read(chatRepositoryProvider)
                            .watchGroupMessages(widget.groupId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final files = (snapshot.data ?? const <MessageModel>[])
                              .where((m) => m.hasAttachment)
                              .toList();

                          if (files.isEmpty) {
                            return const EmptyStateView(
                              message: 'No files shared yet',
                              icon: Icons.folder_open_outlined,
                            );
                          }

                          return ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final msg = files[index];
                              final isImage = FileViewerHelper.isImageType(
                                msg.fileType,
                                msg.fileUrl,
                              );
                              final isOwner = msg.senderEmail.toLowerCase() ==
                                  currentUser.toLowerCase();
                              final uploader = _resolveName(msg.senderEmail);
                              final time = DateFormatter.formatMessageTime(
                                msg.timestamp,
                              );
                              final typeLabel = FileViewerHelper.displayFileType(
                                msg.fileType,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => FileViewerHelper.openSharedFile(
                                    context,
                                    url: msg.fileUrl!,
                                    fileType: msg.fileType,
                                    fileName: msg.fileName,
                                  ),
                                  onLongPress: isOwner
                                      ? () => _confirmUnsend(msg)
                                      : null,
                                  child: EduCard(
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 16,
                                    child: Row(
                                      children: [
                                        Text(
                                          msg.isMeeting
                                              ? '📹'
                                              : (isImage ? '🖼️' : '📄'),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.fileName ?? 'Unknown File',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$typeLabel • Shared by $uploader • $time',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 18,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
