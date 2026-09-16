import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qibla_time/features/library/models/book_model.dart';
import 'package:qibla_time/features/library/services/book_download_service.dart';

const book = IslamHouseBook(
  id: 1,
  title: 'Test',
  titleArabic: '',
  description: '',
  author: '',
  category: '',
  language: 'en',
  downloadUrl: 'https://example.com/book.pdf',
  readUrl: '',
  coverUrl: '',
  format: 'PDF',
  size: '',
  pages: 1,
  rating: 0,
  downloads: 0,
);
final pdf = utf8.encode('%PDF-1.7\nTest fixture\n%%EOF\n');

class StreamClient extends http.BaseClient {
  StreamClient(this.respond);
  final Future<http.StreamedResponse> Function() respond;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => respond();
}

class LocalDownloads extends BookDownloadService {
  LocalDownloads(this.path, http.Client client, {super.timeout})
      : super(client: client);
  final String path;
  @override
  Future<String> getLocalPath(IslamHouseBook book) async => path;
}

void main() {
  late Directory directory;
  late File target;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('book-download-test-');
    target = File('${directory.path}/1.pdf');
  });
  tearDown(() async => directory.delete(recursive: true));

  LocalDownloads service(Stream<List<int>> stream,
          {int? length}) =>
      LocalDownloads(
          target.path,
          StreamClient(() async =>
              http.StreamedResponse(stream, 200, contentLength: length)));

  test('publishes a complete PDF only after the stream finishes', () async {
    final stream = StreamController<List<int>>();
    final downloads = service(stream.stream, length: pdf.length);
    final started = Completer<void>();
    final future = downloads.downloadBook(book, onProgress: (_) {
      if (!started.isCompleted) started.complete();
    });
    await started.future;
    expect(await downloads.isDownloaded(book), false);
    stream.add(pdf);
    await stream.close();
    expect((await future).path, target.path);
    expect(await downloads.isDownloaded(book), true);
    expect(await target.readAsBytes(), pdf);
    expect(await directory.list().length, 1);
  });

  test('interrupted replacement preserves the previous PDF', () async {
    await target.writeAsBytes(pdf);
    final downloads =
        service(Stream<List<int>>.error(const SocketException('offline')));
    await expectLater(
        downloads.downloadBook(book), throwsA(isA<SocketException>()));
    expect(await target.readAsBytes(), pdf);
    expect(await directory.list().length, 1);
  });

  test('valid response without content length replaces the old PDF', () async {
    await target.writeAsString('%PDF-1.4\nOld fixture\n%%EOF');
    final downloads = service(Stream.value(pdf));
    await downloads.downloadBook(book);
    expect(await target.readAsBytes(), pdf);
    expect(await downloads.isDownloaded(book), true);
    expect(await directory.list().length, 1);
  });

  test('HTTP failure preserves the previous PDF', () async {
    await target.writeAsBytes(pdf);
    final downloads = LocalDownloads(
        target.path,
        StreamClient(
            () async => http.StreamedResponse(const Stream.empty(), 503)));
    await expectLater(
        downloads.downloadBook(book), throwsA(isA<HttpException>()));
    expect(await target.readAsBytes(), pdf);
  });

  test('rejects silently truncated response and cleans temporary file',
      () async {
    final downloads = service(Stream.value(pdf), length: pdf.length + 100);
    await expectLater(downloads.downloadBook(book), throwsFormatException);
    expect(await target.exists(), false);
    expect(await directory.list().length, 0);
  });

  for (final body in ['', '<html>Error</html>', '%PDF-1.7\ntruncated']) {
    test('rejects empty, HTML or incomplete PDF: $body', () async {
      final downloads = service(Stream.value(utf8.encode(body)));
      await expectLater(downloads.downloadBook(book), throwsFormatException);
      expect(await target.exists(), false);
    });
  }

  test('does not report legacy partial files as downloaded', () async {
    await target.writeAsString('%PDF-1.7\npartial');
    final downloads = service(const Stream.empty());
    expect(await downloads.isDownloaded(book), false);
    expect(await target.exists(), true);
  });

  test('idle download times out and preserves previous PDF', () async {
    await target.writeAsBytes(pdf);
    final stream = StreamController<List<int>>();
    final downloads = LocalDownloads(
      target.path,
      StreamClient(() async => http.StreamedResponse(stream.stream, 200)),
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(
        downloads.downloadBook(book), throwsA(isA<TimeoutException>()));
    await stream.close();
    expect(await target.readAsBytes(), pdf);
    expect(await directory.list().length, 1);
  });

  test('request timeout does not modify existing PDF', () async {
    await target.writeAsBytes(pdf);
    final downloads = LocalDownloads(
      target.path,
      StreamClient(() => Completer<http.StreamedResponse>().future),
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(
        downloads.downloadBook(book), throwsA(isA<TimeoutException>()));
    expect(await target.readAsBytes(), pdf);
  });
}
