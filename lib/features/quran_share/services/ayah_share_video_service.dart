import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/services/quran_audio_download_service.dart';
import 'ayah_share_image_service.dart';
import 'ayah_share_service.dart';

final ayahShareVideoServiceProvider = Provider<AyahShareVideoService>((ref) {
  return AyahShareVideoService(ref);
});

const _ayahAudioUnavailableMessage =
    'No se pudo obtener el audio para este ayah';

class AyahShareVideoDraft {
  const AyahShareVideoDraft({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.audioPathOrUrl,
    required this.isLocalAudio,
    required this.exportMode,
  });

  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int ayahNumber;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String audioPathOrUrl;
  final bool isLocalAudio;
  final AyahShareExportMode exportMode;

  String get referenceLabel => '$surahNameLatin ($surahNumber:$ayahNumber)';
}

class NativeVideoExportException implements Exception {
  const NativeVideoExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AyahAudioUnavailableException implements Exception {
  const AyahAudioUnavailableException();

  @override
  String toString() => _ayahAudioUnavailableMessage;
}

class AyahShareVideoService {
  static const Size _videoSize = Size(1080, 1920);
  static const int _videoFps = 30;
  static const _temporaryMaxAge = Duration(days: 1);
  static const _temporaryFilePrefixes = <String>[
    'ayah_video_',
  ];
  static const _nativeChannel = MethodChannel('com.qiblatime/video_export');
  static const _galleryChannel = MethodChannel('com.qiblatime/gallery');
  static const _alafasyAudioBaseUrl =
      'https://everyayah.com/data/Alafasy_128kbps';
  static const _legacyAlafasyAudioBaseUrl =
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy';

  AyahShareVideoService(this._ref);

  final Ref _ref;

  Future<AyahShareVideoDraft?> prepareDraft({
    required SurahSummary summary,
    required SurahAyah ayah,
    bool includeArabic = true,
    bool includeTranslation = true,
    AyahShareExportMode exportMode = AyahShareExportMode.storyCanvas,
  }) async {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }

    final localPath = await _ref
        .read(quranAudioDownloadServiceProvider)
        .getDownloadedAyahPath(summary.number, ayah);

    final preferredAudio = localPath ?? _safeAudioUrlFor(summary.number, ayah);
    if (preferredAudio.isEmpty) {
      throw const AyahAudioUnavailableException();
    }

    return AyahShareVideoDraft(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: ayah.numberInSurah,
      arabicText: includeArabic ? ayah.arabic : '',
      transliteration: includeArabic ? ayah.transliteration : '',
      translation: includeTranslation ? ayah.translation : '',
      audioPathOrUrl: preferredAudio,
      isLocalAudio: localPath != null,
      exportMode: exportMode,
    );
  }

  Future<File> exportVideo(AyahShareVideoDraft draft) async {
    if (Platform.isAndroid) {
      return _exportVideoNativeAndroid(draft);
    }
    // Native video export is currently implemented only on Android. The old
    // GPL fallback was removed to keep GPL code out of release builds.
    throw const NativeVideoExportException(
      'Video export is not available on this platform yet.',
    );
  }

  Future<void> saveVideoToGallery(File file) async {
    if (!await file.exists()) {
      throw const NativeVideoExportException('Failed to save video.');
    }

    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (!status.isGranted) {
        throw const NativeVideoExportException('Failed to save video.');
      }
    } else if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt <= 28) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw const NativeVideoExportException('Failed to save video.');
        }
      }
    }

    try {
      final saved = await _galleryChannel.invokeMethod<bool>(
        'saveVideoToGallery',
        {'path': file.path},
      );
      if (saved != true) {
        throw const NativeVideoExportException('Failed to save video.');
      }
    } on PlatformException catch (error) {
      throw NativeVideoExportException(
        error.message ?? 'Failed to save video.',
      );
    }
  }

  Future<File> _exportVideoNativeAndroid(AyahShareVideoDraft draft) async {
    debugPrint('AyahShareVideoService.exportVideo: native android start');

    final tempDirectory = await getTemporaryDirectory();
    final workingDirectory = await Directory(
      '${tempDirectory.path}/ayah_share_video',
    ).create(recursive: true);
    await _deleteOldTemporaryFiles(workingDirectory);
    final fileStem = _fileStemFor(draft);

    final imageFile = await _renderShareImageFrame(
      draft: draft,
      workingDirectory: workingDirectory,
    );

    final audioFile = await _ensureAudioFile(
      draft: draft,
      directory: workingDirectory,
      fileStem: fileStem,
    );

    final outputFile = File('${workingDirectory.path}/${fileStem}_video.mp4');
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    try {
      final resultPath = await _nativeChannel.invokeMethod<String>(
        'exportStillVideo',
        <String, Object?>{
          'imagePath': imageFile.path,
          'audioPath': audioFile.path,
          'outputPath': outputFile.path,
          'width': _videoSize.width.round(),
          'height': _videoSize.height.round(),
          'fps': _videoFps,
          'videoBitrate': 2500000,
          'audioBitrate': 192000,
        },
      );
      if (resultPath == null || resultPath.isEmpty) {
        throw const NativeVideoExportException(
          'Native exporter returned empty path.',
        );
      }
      final out = File(resultPath);
      if (!await out.exists()) {
        throw NativeVideoExportException(
          'Native exporter finished without creating output: ${out.path}',
        );
      }
      final outputLength = await out.length();
      if (outputLength <= 0) {
        throw NativeVideoExportException(
          'Native exporter created an empty output file: ${out.path}',
        );
      }
      return out;
    } on PlatformException catch (e, st) {
      final message = _nativePlatformErrorMessage(e);
      AppLogger.error(
        message,
        error: e,
        stackTrace: st,
      );
      throw NativeVideoExportException(message);
    }
  }

  Future<void> _deleteOldTemporaryFiles(Directory directory) async {
    final cutoff = DateTime.now().subtract(_temporaryMaxAge);
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!_temporaryFilePrefixes.any(name.startsWith)) continue;
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to clean old ayah video temporary files.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<File> _renderShareImageFrame({
    required AyahShareVideoDraft draft,
    required Directory workingDirectory,
  }) async {
    final tokens = QiblaThemes.current;

    final summary = SurahSummary(
      number: draft.surahNumber,
      nameArabic: draft.surahNameArabic,
      nameLatin: draft.surahNameLatin,
      revelationType: '',
      ayahCount: 0,
    );
    final ayah = SurahAyah(
      number: 0,
      numberInSurah: draft.ayahNumber,
      arabic: draft.arabicText,
      transliteration: draft.transliteration,
      translation: draft.translation,
      audioUrl: '',
    );

    return AyahShareService().exportAyahImagePng(
      summary,
      ayah,
      tokens,
      // Always use storyCanvas for video so the PNG has a fully opaque
      // background. Android's bitmapToNV21 ignores the alpha channel, so any
      // transparent pixel becomes black; storyCanvas fills the canvas with
      // bgPage before drawing the card, giving MediaCodec correct ARGB data.
      mode: AyahShareExportMode.storyCanvas,
      includeArabic: draft.arabicText.trim().isNotEmpty,
      includeTranslation: draft.translation.trim().isNotEmpty,
      directory: workingDirectory,
    );
  }

  String _nativePlatformErrorMessage(PlatformException error) {
    final buffer = StringBuffer()
      ..writeln('Native Android video export failed')
      ..writeln('code: ${error.code}');

    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      buffer.writeln('message: $message');
    }

    final details = error.details;
    if (details is Map) {
      final type = details['type'];
      final nativeMessage = details['message'];
      final lastStep = details['lastStep'];
      final stackTrace = details['stackTrace'];

      if (type != null) {
        buffer.writeln('nativeType: $type');
      }
      if (nativeMessage != null) {
        buffer.writeln('nativeMessage: $nativeMessage');
      }
      if (lastStep != null) {
        buffer.writeln('lastStep: $lastStep');
      }
      if (stackTrace != null) {
        buffer.writeln('nativeStackTrace:');
        buffer.write(stackTrace);
      }
    } else if (details != null) {
      buffer.writeln('details: $details');
    }

    return buffer.toString().trim();
  }

  Future<File> _ensureAudioFile({
    required AyahShareVideoDraft draft,
    required Directory directory,
    required String fileStem,
  }) async {
    if (draft.isLocalAudio) {
      final file = File(draft.audioPathOrUrl);
      if (!await file.exists()) {
        throw const AyahAudioUnavailableException();
      }
      return file;
    }

    final uri = Uri.tryParse(draft.audioPathOrUrl);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      throw const AyahAudioUnavailableException();
    }

    final extension = _audioExtensionFromUri(uri);
    final downloadedFile = File(
      '${directory.path}/${fileStem}_audio$extension',
    );

    late final http.Response response;
    try {
      response = await http.get(uri);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to download ayah audio for video: $uri',
        error: e,
        stackTrace: stackTrace,
      );
      throw const AyahAudioUnavailableException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.error(
        'Failed to download ayah audio for video: HTTP ${response.statusCode} $uri',
      );
      throw const AyahAudioUnavailableException();
    }
    if (response.bodyBytes.isEmpty) {
      AppLogger.error('Downloaded ayah audio was empty: $uri');
      throw const AyahAudioUnavailableException();
    }

    await downloadedFile.writeAsBytes(response.bodyBytes, flush: true);
    return downloadedFile;
  }

  String _safeAudioUrlFor(int surahNumber, SurahAyah ayah) {
    final currentUrl = ayah.audioUrl.trim();
    if (currentUrl.isEmpty ||
        currentUrl.startsWith(_legacyAlafasyAudioBaseUrl)) {
      return _alafasyAudioUrlFor(surahNumber, ayah.numberInSurah);
    }
    return currentUrl;
  }

  String _alafasyAudioUrlFor(int surahNumber, int numberInSurah) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = numberInSurah.toString().padLeft(3, '0');
    return '$_alafasyAudioBaseUrl/$surah$ayah.mp3';
  }

  String _fileStemFor(AyahShareVideoDraft draft) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ayah_video_${draft.surahNumber}_${draft.ayahNumber}_$timestamp';
  }

  String _audioExtensionFromUri(Uri uri) {
    final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == lastSegment.length - 1) {
      return '.mp3';
    }

    final extension = lastSegment.substring(dotIndex);
    final sanitized = extension.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');
    if (sanitized.isEmpty || !sanitized.startsWith('.')) {
      return '.mp3';
    }
    return sanitized;
  }
}
