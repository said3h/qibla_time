import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';

class BookDownloadService {
  BookDownloadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<File> downloadBook(
    IslamHouseBook book, {
    void Function(double? progress)? onProgress,
  }) async {
    final downloadUrl = _resolvedDownloadUrl(book);
    if (downloadUrl.isEmpty) {
      throw Exception('Missing download URL');
    }

    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid download URL');
    }

    final request = http.Request('GET', uri);
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download file (${response.statusCode})',
        uri: uri,
      );
    }

    final file = File(await getLocalPath(book));
    await file.parent.create(recursive: true);

    IOSink? sink;
    try {
      sink = file.openWrite();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      onProgress?.call(totalBytes == null || totalBytes <= 0 ? null : 0);

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          onProgress?.call(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      onProgress?.call(1);
      return file;
    } catch (_) {
      await sink?.close();
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<void> deleteBook(IslamHouseBook book) async {
    final file = File(await getLocalPath(book));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> isDownloaded(IslamHouseBook book) async {
    final file = File(await getLocalPath(book));
    return file.exists();
  }

  Future<String> getLocalPath(IslamHouseBook book) async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDirectory = Directory('${directory.path}${Platform.pathSeparator}books');
    return '${booksDirectory.path}${Platform.pathSeparator}${book.id}.pdf';
  }

  String _resolvedDownloadUrl(IslamHouseBook book) {
    final downloadUrl = book.downloadUrl.trim();
    if (downloadUrl.isNotEmpty) {
      return downloadUrl;
    }
    return book.readUrl.trim();
  }
}

final bookDownloadServiceProvider = Provider<BookDownloadService>((ref) {
  return BookDownloadService();
});
