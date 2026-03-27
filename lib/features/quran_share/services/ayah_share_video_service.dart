import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran/models/quran_models.dart';
import '../../quran/services/quran_audio_download_service.dart';

final ayahShareVideoServiceProvider = Provider<AyahShareVideoService>((ref) {
  return AyahShareVideoService(ref);
});

class AyahShareVideoDraft {
  const AyahShareVideoDraft({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.ayahNumber,
    required this.arabicText,
    required this.translation,
    required this.audioPathOrUrl,
    required this.isLocalAudio,
  });

  final int surahNumber;
  final String surahNameLatin;
  final int ayahNumber;
  final String arabicText;
  final String translation;
  final String audioPathOrUrl;
  final bool isLocalAudio;

  String get referenceLabel => '$surahNameLatin ($surahNumber:$ayahNumber)';
}

class AyahShareVideoService {
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
      ayahNumber: ayah.numberInSurah,
      arabicText: ayah.arabic,
      translation: ayah.translation,
      audioPathOrUrl: preferredAudio,
      isLocalAudio: localPath != null,
    );
  }

  Future<File> exportVideo(AyahShareVideoDraft draft) {
    throw UnimplementedError(
      'TODO: compose the ayah share card and recitation audio into a video export.',
    );
  }
}
