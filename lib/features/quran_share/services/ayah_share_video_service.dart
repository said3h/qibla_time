import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/services/quran_audio_download_service.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import 'ayah_share_image_service.dart';

final ayahShareVideoServiceProvider = Provider<AyahShareVideoService>((ref) {
  return AyahShareVideoService(ref);
});

class AyahShareVideoDraft {
  const AyahShareVideoDraft({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.arabicText,
    required this.translation,
    required this.audioPathOrUrl,
    required this.isLocalAudio,
  });

  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int ayahNumber;
  final String arabicText;
  final String translation;
  final String audioPathOrUrl;
  final bool isLocalAudio;

  String get referenceLabel => '$surahNameLatin ($surahNumber:$ayahNumber)';
}

class AyahShareVideoService {
  static const Size _videoSize = Size(1080, 1920);
  static const int _videoFps = 30;

  AyahShareVideoService(this._ref);

  final Ref _ref;

  Future<AyahShareVideoDraft?> prepareDraft({
    required SurahSummary summary,
    required SurahAyah ayah,
  }) async {
    final localPath = await _ref
        .read(quranAudioDownloadServiceProvider)
        .getDownloadedAyahPath(summary.number, ayah);

    final preferredAudio = localPath ?? ayah.audioUrl;
    if (preferredAudio.isEmpty) {
      return null;
    }

    return AyahShareVideoDraft(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: ayah.numberInSurah,
      arabicText: ayah.arabic,
      translation: ayah.translation,
      audioPathOrUrl: preferredAudio,
      isLocalAudio: localPath != null,
    );
  }

  Future<File> exportVideo(AyahShareVideoDraft draft) async {
    final tempDirectory = await getTemporaryDirectory();
    final workingDirectory = await Directory(
      '${tempDirectory.path}/ayah_share_video',
    ).create(recursive: true);
    final fileStem = _fileStemFor(draft);

    final imageFile = await AyahShareImageService.savePng(
      data: AyahShareData(
        surahNumber: draft.surahNumber,
        surahNameLatin: draft.surahNameLatin,
        surahNameArabic: draft.surahNameArabic,
        ayahNumber: draft.ayahNumber,
        arabicText: draft.arabicText,
        translation: draft.translation,
        branding: 'App: Qibla Time',
      ),
      theme: AyahShareThemeData.fromTokens(
        QiblaThemes.current,
        transparentBackground: true,
      ),
      transparentBackground: true,
      mode: AyahShareExportMode.cardOnly,
      fileName: '${fileStem}_card',
      directory: workingDirectory,
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

    final command = _buildFfmpegCommand(
      imageFile: imageFile,
      audioFile: audioFile,
      outputFile: outputFile,
    );

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      throw StateError(
        'FFmpeg failed to export the ayah video.${output == null || output.trim().isEmpty ? '' : '\n$output'}',
      );
    }

    if (!await outputFile.exists()) {
      throw StateError('FFmpeg finished without creating the ayah video file.');
    }

    return outputFile;
  }

  Future<File> _ensureAudioFile({
    required AyahShareVideoDraft draft,
    required Directory directory,
    required String fileStem,
  }) async {
    if (draft.isLocalAudio) {
      final file = File(draft.audioPathOrUrl);
      if (!await file.exists()) {
        throw StateError(
          'The local recitation audio could not be found for this ayah.',
        );
      }
      return file;
    }

    final uri = Uri.tryParse(draft.audioPathOrUrl);
    if (uri == null || !uri.hasScheme) {
      throw StateError('The ayah audio URL is invalid.');
    }

    final extension = _audioExtensionFromUri(uri);
    final downloadedFile = File(
      '${directory.path}/${fileStem}_audio$extension',
    );

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Could not download the recitation audio (HTTP ${response.statusCode}).',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw StateError('The downloaded recitation audio was empty.');
    }

    await downloadedFile.writeAsBytes(response.bodyBytes, flush: true);
    return downloadedFile;
  }

  String _buildFfmpegCommand({
    required File imageFile,
    required File audioFile,
    required File outputFile,
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
        '-c:v libx264 -preset veryfast -tune stillimage '
        '-c:a aac -b:a 192k '
        '-pix_fmt yuv420p -r $_videoFps '
        '-shortest -movflags +faststart '
        '$outputPath';
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
