import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../widgets/edu_header_and_tiles.dart';

/// Shared MIME inference and attachment/link opening utilities for Chat & Shared Files.
abstract final class FileViewerHelper {
  static String guessMimeType(String? extension) {
    final ext = (extension ?? '').trim().toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'gif':
        return 'image/$ext';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  static bool isImageType(String? fileType, [String? url]) {
    final lowerType = (fileType ?? '').toLowerCase();
    if (lowerType.contains('image')) return true;
    final lowerUrl = (url ?? '').toLowerCase();
    return lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');
  }

  static String displayFileType(String? fileType) {
    final raw = (fileType ?? '').trim();
    if (raw.isEmpty) return 'Document';
    if (raw == 'meeting') return 'Meeting Link';
    if (raw.startsWith('image/')) {
      return 'Image (${raw.split('/').last.toUpperCase()})';
    }
    if (raw == 'application/pdf') return 'PDF Document';
    if (raw.contains('wordprocessingml') || raw == 'application/msword') {
      return 'Word Document';
    }
    if (raw.contains('presentationml') || raw == 'application/vnd.ms-powerpoint') {
      return 'Presentation';
    }
    if (raw.contains('spreadsheetml') || raw == 'application/vnd.ms-excel') {
      return 'Spreadsheet';
    }
    if (raw == 'application/octet-stream') return 'File';
    return raw;
  }

  static Future<void> openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      showEduSnackBar(context, 'Invalid URL');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showEduSnackBar(context, 'Could not open link');
      }
    } catch (_) {
      if (context.mounted) showEduSnackBar(context, 'Could not open link');
    }
  }

  static Future<void> openSharedFile(
    BuildContext context, {
    required String url,
    String? fileType,
    String? fileName,
  }) async {
    if (isImageType(fileType, url)) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName ?? 'Image Preview',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(
                      height: 140,
                      child: Center(
                        child: Text('Preview unavailable. Open in browser.'),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openExternalUrl(context, url);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Browser'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    await openExternalUrl(context, url);
  }
}
