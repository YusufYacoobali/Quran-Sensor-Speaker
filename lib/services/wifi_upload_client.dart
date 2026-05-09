import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WifiUploadResult {
  const WifiUploadResult({
    required this.statusCode,
    required this.responseBody,
  });

  final int statusCode;
  final String responseBody;
}

class WifiUploadClient {
  const WifiUploadClient();

  Future<WifiUploadResult> uploadBytes({
    required Uri uri,
    required String method,
    required List<int> bytes,
    required String mimeType,
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client
          .openUrl(method.toUpperCase(), uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.parse(mimeType);
      request.contentLength = bytes.length;

      // Keep writes small so the UI receives smooth progress updates and the
      // ESP32-side HTTP server is not flooded with one huge buffer.
      const chunkSize = 4096;
      var sent = 0;
      while (sent < bytes.length) {
        final end = (sent + chunkSize).clamp(0, bytes.length);
        request.add(bytes.sublist(sent, end));
        sent = end;
        onProgress(sent / bytes.length);
        await request.flush();
      }

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Upload failed with HTTP ${response.statusCode}: $responseBody',
          uri: uri,
        );
      }
      return WifiUploadResult(
        statusCode: response.statusCode,
        responseBody: responseBody,
      );
    } finally {
      client.close(force: true);
    }
  }
}
