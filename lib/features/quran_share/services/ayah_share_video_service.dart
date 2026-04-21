import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
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
    try {
      final tempDirectory = await getTemporaryDirectory();
      final workingDirectory = await Directory(
        '${tempDirectory.path}/ayah_share_video',
      ).create(recursive: true);
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

      final audioDurationSeconds = await _getAudioDuration(audioFile);

      if (audioDurationSeconds <= 0) {
        throw StateError(
          'Could not determine audio duration for ayah video.',
        );
      }

      final outputFile = File('${workingDirectory.path}/${fileStem}_video.mp4');
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      final command = _buildFfmpegCommand(
        imageFile: imageFile,
        audioFile: audioFile,
        outputFile: outputFile,
        audioDurationSeconds: audioDurationSeconds,
      );

      AppLogger.info('exportVideo: running FFmpeg command:\n$command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      // getAllLogsAsString captura tanto stdout como stderr — necesario porque
      // FFmpeg escribe la mayor parte del diagnóstico en stderr.
      final logs = await session.getAllLogsAsString() ?? '';
      AppLogger.info(
          'exportVideo: FFmpeg returnCode=${returnCode?.getValue()} logs:\n$logs');

      if (!ReturnCode.isSuccess(returnCode)) {
        // Retry always with the software fallback encoder.
        AppLogger.info(
            'exportVideo: primary encoder failed, retrying with mpeg4 fallback...');

        final fallbackCommand = _buildFfmpegCommand(
          imageFile: imageFile,
          audioFile: audioFile,
          outputFile: outputFile,
          audioDurationSeconds: audioDurationSeconds,
          forceFallbackEncoder: true,
        );

        AppLogger.info('exportVideo: fallback command:\n$fallbackCommand');

        final retrySession = await FFmpegKit.execute(fallbackCommand);
        final retryCode = await retrySession.getReturnCode();
        final retryLogs = await retrySession.getAllLogsAsString() ?? '';
        AppLogger.info(
            'exportVideo: fallback returnCode=${retryCode?.getValue()} logs:\n$retryLogs');

        if (!ReturnCode.isSuccess(retryCode)) {
          throw StateError(
            'FFmpeg failed (primary + fallback).\n'
            'Primary logs: $logs\n'
            'Fallback logs: $retryLogs',
          );
        }
      }

      if (!await outputFile.exists()) {
        throw StateError(
            'FFmpeg finished without creating the ayah video file.');
      }

      return outputFile;
    } catch (e, stackTrace) {
      AppLogger.error(
        'exportVideo: FAILED ${e.runtimeType}: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
      mode: draft.exportMode,
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

  Future<double> _getAudioDuration(File audioFile) async {
    // FFmpeg escribe la info de duración en stderr, no en stdout.
    // getOutput() solo captura stdout → siempre devolvía null/vacío.
    // getAllLogsAsString() captura ambos streams.
    final session = await FFmpegKit.execute(
      '-i ${_quoteForFfmpeg(audioFile.path)} -f null -',
    );
    final logs = await session.getAllLogsAsString();

    AppLogger.info('_getAudioDuration: logs=$logs');

    if (logs == null || logs.isEmpty) {
      AppLogger.error(
          '_getAudioDuration: no logs from FFmpeg — cannot determine duration');
      return 0;
    }

    final durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
    final match = durationRegex.firstMatch(logs);

    if (match == null) {
      AppLogger.error('_getAudioDuration: Duration not found in logs:\n$logs');
      return 0;
    }

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);
    final total = hours * 3600 + minutes * 60 + seconds + centiseconds / 100;

    AppLogger.info('_getAudioDuration: parsed duration=$total s');
    return total;
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

  String _buildFfmpegCommand({
    required File imageFile,
    required File audioFile,
    required File outputFile,
    required double audioDurationSeconds,
    bool forceFallbackEncoder = false,
  }) {
    final backgroundColor = _ffmpegColor(QiblaThemes.current.bgPage);
    final width = _videoSize.width.round();
    final height = _videoSize.height.round();
    final imagePath = _quoteForFfmpeg(imageFile.path);
    final audioPath = _quoteForFfmpeg(audioFile.path);
    final outputPath = _quoteForFfmpeg(outputFile.path);
    final filter =
        'color=c=$backgroundColor:s=${width}x$height:r=$_videoFps[bg];'
        '[bg][0:v]overlay=(W-w)/2:(H-h)/2:format=auto,format=yuv420p[v]';

    return '-y '
        '-loop 1 -framerate $_videoFps -i $imagePath '
        '-i $audioPath '
        '-filter_complex "$filter" '
        '-map "[v]" -map 1:a:0 '
        '${_videoEncoderArgs(forceFallbackEncoder: forceFallbackEncoder)} '
        '-c:a aac -b:a 192k '
        '-pix_fmt yuv420p -r $_videoFps '
        '-t $audioDurationSeconds '
        '-movflags +faststart '
        '$outputPath';
  }

  String _videoEncoderArgs({required bool forceFallbackEncoder}) {
    if (forceFallbackEncoder) {
      // Baseline encoder that should exist in non-GPL builds.
      return '-c:v mpeg4 -q:v 5 -tag:v mp4v';
    }

    if (Platform.isIOS) {
      // Hardware H.264 encoder (non-GPL).
      return '-c:v h264_videotoolbox -b:v 2500k';
    }
    if (Platform.isAndroid) {
      // Hardware H.264 encoder (non-GPL). Availability varies by device.
      return '-c:v h264_mediacodec -b:v 2500k';
    }

    // Desktop/dev fallback.
    return '-c:v mpeg4 -q:v 5 -tag:v mp4v';
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

  String _quoteForFfmpeg(String path) {
    final normalized = path.replaceAll('\\', '/').replaceAll('"', '\\"');
    return '"$normalized"';
  }

  String _ffmpegColor(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '0x${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
