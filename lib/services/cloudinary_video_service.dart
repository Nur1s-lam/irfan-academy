import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    required this.durationSeconds,
  });

  final String secureUrl;
  final String publicId;
  final String fileName;
  final int fileSize;
  final String contentType;
  final int durationSeconds;
}

class CloudinaryUploadCancelled implements Exception {
  const CloudinaryUploadCancelled();
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryVideoService {
  CloudinaryVideoService({http.Client? client})
    : _client = client ?? http.Client();

  static const cloudName = 'rrup0mxf';
  static const uploadPreset = 'irfan_video_demo';
  static const chunkSize = 8 * 1024 * 1024;
  static const directUploadLimit = 95 * 1024 * 1024;
  static const maxAttempts = 4;

  final http.Client _client;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

  Future<CloudinaryUploadResult> uploadVideo(
    XFile file, {
    required void Function(double progress) onProgress,
    bool Function()? isCancelled,
  }) async {
    final total = await file.length();
    if (total <= 0) throw const FormatException('Выбран пустой видеофайл.');

    if (total <= directUploadLimit) {
      final data = await _sendDirect(
        file: file,
        total: total,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      return _result(file, total, data);
    }

    final uploadId =
        '${DateTime.now().microsecondsSinceEpoch}-${file.name.hashCode.abs()}';
    Map<String, dynamic>? finalResponse;

    for (var start = 0; start < total; start += chunkSize) {
      _throwIfCancelled(isCancelled);
      final endExclusive = (start + chunkSize).clamp(0, total);
      final bytes = await _readRange(file, start, endExclusive);
      finalResponse = await _sendChunk(
        bytes: bytes,
        fileName: file.name,
        uploadId: uploadId,
        start: start,
        endInclusive: endExclusive - 1,
        total: total,
        isCancelled: isCancelled,
      );
      onProgress(endExclusive / total);
    }

    return _result(file, total, finalResponse);
  }

  CloudinaryUploadResult _result(
    XFile file,
    int total,
    Map<String, dynamic>? data,
  ) {
    final secureUrl = data?['secure_url']?.toString();
    final publicId = data?['public_id']?.toString();
    if (secureUrl == null || publicId == null) {
      throw const FormatException(
        'Cloudinary не вернул данные загруженного видео.',
      );
    }
    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: publicId,
      fileName: file.name,
      fileSize: (data?['bytes'] as num?)?.toInt() ?? total,
      contentType: 'video/${data?['format'] ?? _extension(file.name)}',
      durationSeconds: ((data?['duration'] as num?) ?? 0).round(),
    );
  }

  Future<Map<String, dynamic>> _sendDirect({
    required XFile file,
    required int total,
    required void Function(double progress) onProgress,
    bool Function()? isCancelled,
  }) async {
    _throwIfCancelled(isCancelled);
    final request =
        _ProgressMultipartRequest(
            'POST',
            _uploadUri,
            onProgress: (sent, length) {
              if (isCancelled?.call() ?? false) return;
              onProgress(length == 0 ? 0 : sent / length);
            },
          )
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile(
              'file',
              file.openRead(),
              total,
              filename: file.name,
            ),
          );
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(minutes: 15));
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CloudinaryUploadException(
          _cloudinaryError(body, response.statusCode),
        );
      }
      onProgress(1);
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } on CloudinaryUploadException {
      rethrow;
    } catch (error) {
      throw CloudinaryUploadException(
        'Соединение прервано. Проверьте интернет и повторите загрузку. ($error)',
      );
    }
  }

  Future<Map<String, dynamic>> _sendChunk({
    required Uint8List bytes,
    required String fileName,
    required String uploadId,
    required int start,
    required int endInclusive,
    required int total,
    bool Function()? isCancelled,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _throwIfCancelled(isCancelled);
      try {
        final request = http.MultipartRequest('POST', _uploadUri)
          ..headers['X-Unique-Upload-Id'] = uploadId
          ..headers['Content-Range'] = 'bytes $start-$endInclusive/$total'
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );
        final streamed = await _client
            .send(request)
            .timeout(const Duration(minutes: 5));
        final body = await streamed.stream.bytesToString();
        if (streamed.statusCode >= 400 && streamed.statusCode < 500) {
          throw CloudinaryUploadException(
            _cloudinaryError(body, streamed.statusCode),
          );
        }
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          throw http.ClientException(
            _cloudinaryError(body, streamed.statusCode),
          );
        }
        return Map<String, dynamic>.from(jsonDecode(body) as Map);
      } on CloudinaryUploadException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
        }
      }
    }
    throw Exception('Не удалось отправить часть видео: $lastError');
  }

  Future<Uint8List> _readRange(XFile file, int start, int end) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(start, end)) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  String _cloudinaryError(String body, int status) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message']?.toString() ?? 'Cloudinary HTTP $status';
    } catch (_) {
      return 'Cloudinary HTTP $status';
    }
  }

  void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) throw const CloudinaryUploadCancelled();
  }

  String _extension(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : 'mp4';
}

class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  final void Function(int sent, int total) onProgress;

  @override
  http.ByteStream finalize() {
    final total = contentLength;
    var sent = 0;
    final stream = super.finalize().transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sent += data.length;
          onProgress(sent, total);
          sink.add(data);
        },
      ),
    );
    return http.ByteStream(stream);
  }
}
