import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class CatboxUploadDataSource {
  CatboxUploadDataSource([http.Client? client])
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Uploads file bytes to Catbox (`https://catbox.moe/user/api.php`) using
  /// multipart `reqtype=fileupload`, optionally reporting progress from 0.0 to 1.0.
  Future<String> uploadFileBytes({
    required Uint8List bytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConstants.catboxUploadUrl),
    )
      ..fields['reqtype'] = 'fileupload'
      ..files.add(
        http.MultipartFile.fromBytes(
          'fileToUpload',
          bytes,
          filename: fileName,
        ),
      );

    final http.StreamedResponse streamed;
    if (onProgress != null) {
      final totalBytes = request.contentLength;
      final byteStream = request.finalize();
      var sent = 0;

      final trackedRequest = http.StreamedRequest('POST', request.url)
        ..contentLength = totalBytes;
      trackedRequest.headers.addAll(request.headers);

      // Pump multipart chunks while reporting progress, then send.
      unawaited(
        byteStream
            .transform<List<int>>(
              StreamTransformer.fromHandlers(
                handleData: (chunk, sink) {
                  sent += chunk.length;
                  if (totalBytes > 0) {
                    onProgress((sent / totalBytes).clamp(0.0, 1.0));
                  }
                  sink.add(chunk);
                },
              ),
            )
            .pipe(trackedRequest.sink),
      );
      streamed = await _client.send(trackedRequest);
    } else {
      streamed = await _client.send(request);
    }

    final response = await http.Response.fromStream(streamed);
    final url = response.body.trim();
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        url.startsWith('http')) {
      onProgress?.call(1.0);
      return url;
    }
    throw Exception('Catbox upload failed (${response.statusCode}): $url');
  }
}
