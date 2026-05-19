import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../utils/book_link_launcher.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({
    super.key,
    required this.title,
    required this.source,
    this.isLocalFile = false,
  });

  final String title;
  final String source;
  final bool isLocalFile;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  double? _downloadProgress;
  String? _filePath;
  String? _errorMessage;
  int? _pageCount;
  int? _currentPage;
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _prepareBook();
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  Future<void> _prepareBook() async {
    final source = widget.source.trim();
    if (source.isEmpty) {
      _setLoadError();
      return;
    }

    if (widget.isLocalFile) {
      final file = File(source);
      if (await file.exists()) {
        _setReady(file.path);
      } else {
        _setLoadError();
      }
      return;
    }

    final uri = Uri.tryParse(source);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _setLoadError();
      return;
    }

    _client = http.Client();
    try {
      final file = await _downloadToCache(uri);
      if (!mounted) return;
      _setReady(file.path);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Internal book reader failed to download PDF: url="$source"',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _setLoadError();
    }
  }

  Future<File> _downloadToCache(Uri uri) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}qibla_book_${uri.toString().hashCode}.pdf',
    );

    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    final request = http.Request('GET', uri);
    final response = await _client!.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Book PDF request failed (${response.statusCode})',
        uri: uri,
      );
    }

    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    final totalBytes = response.contentLength;
    var receivedBytes = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (mounted && totalBytes != null && totalBytes > 0) {
          setState(() => _downloadProgress = receivedBytes / totalBytes);
        }
      }
      await sink.flush();
      await sink.close();
      return file;
    } catch (_) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  void _setReady(String path) {
    if (!mounted) return;
    setState(() {
      _filePath = path;
      _isLoading = false;
      _errorMessage = null;
      _downloadProgress = null;
    });
  }

  void _setLoadError() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = context.l10n.bookReaderLoadError;
      _downloadProgress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgPage,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.commonBack,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            color: tokens.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_pageCount != null && _currentPage != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  '${_currentPage! + 1}/$_pageCount',
                  style: GoogleFonts.dmSans(
                    color: tokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _BookReaderLoading(progress: _downloadProgress);
    }

    if (_errorMessage != null || _filePath == null) {
      return _BookReaderError(
        source: _externalSource,
        message: _errorMessage ?? context.l10n.bookReaderLoadError,
      );
    }

    return PDFView(
      filePath: _filePath,
      fitPolicy: FitPolicy.WIDTH,
      enableSwipe: true,
      autoSpacing: true,
      pageFling: true,
      pageSnap: false,
      preventLinkNavigation: true,
      onRender: (pages) {
        if (!mounted) return;
        setState(() {
          _pageCount = pages;
          _currentPage = 0;
        });
      },
      onPageChanged: (page, total) {
        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _pageCount = total;
        });
      },
      onError: (error) {
        AppLogger.error('Internal PDF reader failed', error: error);
        _setLoadError();
      },
      onPageError: (page, error) {
        AppLogger.error(
          'Internal PDF reader failed on page $page',
          error: error,
        );
      },
    );
  }

  String get _externalSource {
    if (widget.isLocalFile) {
      return Uri.file(widget.source).toString();
    }
    return widget.source;
  }
}

class _BookReaderLoading extends StatelessWidget {
  const _BookReaderLoading({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: tokens.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.bookReaderLoading,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookReaderError extends StatelessWidget {
  const _BookReaderError({
    required this.source,
    required this.message,
  });

  final String source;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 42,
              color: tokens.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: source.trim().isEmpty
                  ? null
                  : () => openBookUrl(context, source),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l10n.bookOpenExternally),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
