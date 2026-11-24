import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class CatboxUploadDataSource {
  CatboxUploadDataSource([http.Client? client])
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadFileBytes({
    required Uint8List bytes,
    required String fileName,
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

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final url = response.body.trim();
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        url.startsWith('http')) {
      return url;
    }
    throw Exception('Catbox upload failed (${response.statusCode}): $url');
  }
}
