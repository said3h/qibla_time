import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';

class BookDownloadService {
  BookDownloadService({
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<File> downloadBook(
    IslamHouseBook book, {
    void Function(double? progress)? onProgress,
  }) async {
    final downloadUrl = _resolvedDownloadUrl(book);
    if (downloadUrl.isEmpty) {
      throw Exception('Missing download URL');
    }

    final uri = Uri.tryParse(downloadUrl);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw Exception('Invalid download URL');
    }

    final request = http.Request('GET', uri);
    final response = await _client.send(request).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download file (${response.statusCode})',
        uri: uri,
      );
    }

    final file = File(await getLocalPath(book));
    await file.parent.create(recursive: true);
    // Keep the final PDF untouched until a complete replacement is available.
    final temporaryDirectory = await file.parent.createTemp('.download-');
    final temporaryFile = File('${temporaryDirectory.path}/book.part');

    IOSink? sink;
    try {
      sink = temporaryFile.openWrite();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      onProgress?.call(totalBytes == null || totalBytes <= 0 ? null : 0);

      await for (final chunk in response.stream.timeout(timeout)) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          onProgress?.call(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;
      if (receivedBytes == 0 ||
          (totalBytes != null && receivedBytes != totalBytes) ||
          !await _looksLikeCompletePdf(temporaryFile)) {
        throw const FormatException('Incomplete or invalid PDF download');
      }
      await temporaryFile.rename(file.path);
      onProgress?.call(1);
      return file;
    } finally {
      try {
        await sink?.close();
      } finally {
        await temporaryDirectory.delete(recursive: true);
      }
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
    return _looksLikeCompletePdf(file);
  }

  Future<bool> _looksLikeCompletePdf(File file) async {
    if (!await file.exists()) return false;
    final handle = await file.open();
    try {
      final length = await handle.length();
      if (length < 10) return false;
      final header = String.fromCharCodes(await handle.read(5));
      if (header != '%PDF-') return false;
      await handle.setPosition(length > 1024 ? length - 1024 : 0);
      final tail = String.fromCharCodes(await handle.read(1024));
      return tail.contains('%%EOF');
    } finally {
      await handle.close();
    }
  }

  Future<String> getLocalPath(IslamHouseBook book) async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDirectory =
        Directory('${directory.path}${Platform.pathSeparator}books');
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
