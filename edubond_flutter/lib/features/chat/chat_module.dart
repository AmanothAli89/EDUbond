import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_viewer_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../models/message_model.dart';

class ChatModulePage extends ConsumerStatefulWidget {
  const ChatModulePage({
    super.key,
    this.groupId = '',
    this.groupName = 'Group',
  });

  final String groupId;
  final String groupName;

  @override
  ConsumerState<ChatModulePage> createState() => _ChatModulePageState();
}

class _ChatModulePageState extends ConsumerState<ChatModulePage> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Map<String, String> _nameCache = {};
  final Set<String> _markedReadIds = {};

  late String _groupName;
  String _teachersSubtitle = 'loading info...';
  bool _uploading = false;
  double? _uploadProgress;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _loadGroupInfo();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    if (widget.groupId.isEmpty) return;
    try {
      final info =
          await ref.read(groupRepositoryProvider).getGroupInfo(widget.groupId);
      if (!mounted || info == null) return;
      setState(() {
        _groupName = info.name.isNotEmpty ? info.name : _groupName;
        _teachersSubtitle = info.teachers.isNotEmpty
            ? 'Teachers: ${info.teachers.join(", ")}'
            : 'tap for group info';
      });
    } catch (_) {
      if (mounted) setState(() => _teachersSubtitle = 'tap for group info');
    }
  }

  String _resolveSenderName(String email) {
    final cached = _nameCache[email];
    if (cached != null) return cached;
    _nameCache[email] = email;
    ref.read(authRepositoryProvider).getUserNameByEmail(email).then((name) {
      if (mounted && _nameCache[email] != name) {
        setState(() => _nameCache[email] = name);
      }
    }).catchError((_) {});
    return email;
  }

  Future<void> _sendMessage() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty || widget.groupId.isEmpty) return;
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    if (email.isEmpty) return;
    _messageCtrl.clear();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            groupId: widget.groupId,
            senderEmail: email,
            messageText: msg,
          );
    } catch (e) {
      if (mounted) showEduSnackBar(context, 'Failed to send message: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (_uploading || widget.groupId.isEmpty) return;
    try {
      final file = await ref.read(filePickProvider)();
      if (file == null) return;

      final bytes = file.bytes;
      if (bytes.isEmpty) {
        if (mounted) showEduSnackBar(context, 'Could not read selected file.');
        return;
      }

      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
      });
      if (mounted) showEduSnackBar(context, 'Uploading file (Free Cloud)...');

      final email = ref.read(authRepositoryProvider).activeUserEmail;
      final mime = FileViewerHelper.guessMimeType(file.extension);

      await ref.read(chatRepositoryProvider).uploadAndShareFile(
            groupId: widget.groupId,
            senderEmail: email,
            bytes: bytes,
            fileName: file.name,
            fileType: mime,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );
      if (mounted) showEduSnackBar(context, 'File Shared with Group!');
    } catch (_) {
      if (mounted) showEduSnackBar(context, 'Upload failed. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _showMeetingDialog() async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _MeetingLinkDialog(),
    );
    if (url == null || url.isEmpty || !mounted) return;
    final email = ref.read(authRepositoryProvider).activeUserEmail;
    try {
      await ref.read(chatRepositoryProvider).shareMeetingLink(
            groupId: widget.groupId,
            senderEmail: email,
            meetingUrl: url,
          );
    } catch (_) {
      if (mounted) {
        showEduSnackBar(context, 'Failed to share meeting link');
      }
    }
  }

  Future<void> _confirmUnsend(MessageModel msg) async {
    if (msg.id.isEmpty) {
      showEduSnackBar(
        context,
        'Cannot unsend old messages sent before this update.',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Do you want to unsend this message?'),
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

  Future<void> _openGroupInfo() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.groupInfo,
      arguments: widget.groupId,
    );
    _loadGroupInfo();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = ref.read(authRepositoryProvider).activeUserEmail;
    final currentLower = currentEmail.toLowerCase();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.chatWallpaper,
      appBar: AppBar(
        backgroundColor: AppColors.chatHeaderGreen,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openGroupInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _groupName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _teachersSubtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) {
              if (value == 'info') _openGroupInfo();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'info', child: Text('Group Info')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_uploading)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                if (_uploadProgress != null)
                  Container(
                    width: double.infinity,
                    color: AppColors.softBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      'Uploading file: ${(_uploadProgress! * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          Expanded(
            child: widget.groupId.isEmpty
                ? const Center(child: Text('No group selected'))
                : StreamBuilder<List<MessageModel>>(
                    stream: ref
                        .read(chatRepositoryProvider)
                        .watchGroupMessages(widget.groupId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data ?? const <MessageModel>[];

                      if (messages.length != _lastMessageCount) {
                        _lastMessageCount = messages.length;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollCtrl.hasClients) {
                            _scrollCtrl.jumpTo(
                              _scrollCtrl.position.maxScrollExtent,
                            );
                          }
                        });
                      }

                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final alreadySeen = msg.seenBy.any(
                            (s) => s.toLowerCase() == currentLower,
                          );
                          if (currentEmail.isNotEmpty &&
                              msg.id.isNotEmpty &&
                              !alreadySeen &&
                              !_markedReadIds.contains(msg.id)) {
                            _markedReadIds.add(msg.id);
                            ref.read(chatRepositoryProvider).markMessageAsRead(
                                  groupId: widget.groupId,
                                  messageId: msg.id,
                                  email: currentEmail,
                                );
                          }
                          final isMe = msg.senderEmail.toLowerCase() ==
                              currentLower;
                          return _buildBubble(msg, isMe);
                        },
                      );
                    },
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageModel msg, bool isMe) {
    final senderName = isMe ? '' : _resolveSenderName(msg.senderEmail);
    final timeStr = DateFormatter.formatMessageTime(msg.timestamp);
    final isImage = FileViewerHelper.isImageType(msg.fileType, msg.fileUrl);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _confirmUnsend(msg) : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.chatOutgoingBubble
                : AppColors.chatIncomingBubble,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.chatHeaderGreen,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              if (msg.hasAttachment) ...[
                InkWell(
                  onTap: () {
                    if (msg.isMeeting) {
                      FileViewerHelper.openExternalUrl(context, msg.fileUrl!);
                    } else {
                      FileViewerHelper.openSharedFile(
                        context,
                        url: msg.fileUrl!,
                        fileType: msg.fileType,
                        fileName: msg.fileName,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: msg.isMeeting
                          ? AppColors.softIndigo
                          : AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: msg.isMeeting
                          ? Border.all(color: AppColors.adminHeroStart)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.isMeeting ? '📹' : (isImage ? '🖼️' : '📄'),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.isMeeting
                                    ? '${msg.fileName ?? "Live"} Meeting'
                                    : (msg.fileName ?? 'Attachment'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: msg.isMeeting
                                      ? const Color(0xFF4338CA)
                                      : AppColors.primaryBlue,
                                ),
                              ),
                              if (msg.isMeeting)
                                const Text(
                                  'Click to Join',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.adminHeroStart,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (msg.message.isNotEmpty) const SizedBox(height: 6),
              ],
              if (msg.message.isNotEmpty) _linkifiedText(msg.message),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Text(
                      msg.seenBy.length > 1 ? '✓✓' : '✓',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: msg.seenBy.length > 1
                            ? AppColors.chatSeenBlue
                            : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkifiedText(String text) {
    final regex = RegExp(
      r'(https?:\/\/[^\s]+|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
    );
    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final token = match.group(0)!;
      final launchTarget =
          token.contains('@') && !token.startsWith('http')
              ? 'mailto:$token'
              : token;
      spans.add(
        TextSpan(
          text: token,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => FileViewerHelper.openExternalUrl(
                  context,
                  launchTarget,
                ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Colors.black),
        children: spans,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadFile,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text('📎', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showMeetingDialog,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text('📹', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: AppColors.chatHeaderGreen,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendMessage,
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: CustomPaint(
                      size: Size(24, 24),
                      painter: SendIconPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingLinkDialog extends StatefulWidget {
  const _MeetingLinkDialog();

  @override
  State<_MeetingLinkDialog> createState() => _MeetingLinkDialogState();
}

class _MeetingLinkDialogState extends State<_MeetingLinkDialog> {
  final _linkCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Meeting Link'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _linkCtrl,
              decoration: InputDecoration(
                hintText: 'Paste Google Meet, Zoom, or Jitsi link',
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: https://meet.google.com/abc-defg-hij',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final url = _linkCtrl.text.trim();
            final err = Validators.httpUrl(url);
            if (err != null) {
              setState(() => _errorText = err);
              return;
            }
            Navigator.of(context).pop(url);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(88, 40)),
          child: const Text('Share'),
        ),
      ],
    );
  }
}
