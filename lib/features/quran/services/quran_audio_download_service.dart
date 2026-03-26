import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/quran_models.dart';

final quranAudioDownloadServiceProvider =
    Provider<QuranAudioDownloadService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return QuranAudioDownloadService(client: client);
});

class QuranAudioDownloadService {
  QuranAudioDownloadService({required http.Client client}) : _client = client;

  final http.Client _client;

  Future<SurahAudioDownloadState> getDownloadState(SurahDetail detail) async {
    final downloadableAyahs = _downloadableAyahs(detail);
    final totalAyahs = downloadableAyahs.length;
    if (totalAyahs == 0) {
      return const SurahAudioDownloadState(
        status: SurahAudioDownloadStatus.notDownloaded,
        availableAyahs: 0,
        downloadedAyahs: 0,
      );
    }

    var downloadedAyahs = 0;
    for (final ayah in downloadableAyahs) {
      final file = await _localFileForAyah(detail.summary.number, ayah);
      if (await file.exists()) {
        downloadedAyahs++;
      }
    }

    return SurahAudioDownloadState(
      status: downloadedAyahs == totalAyahs
          ? SurahAudioDownloadStatus.downloaded
          : SurahAudioDownloadStatus.notDownloaded,
      availableAyahs: totalAyahs,
      downloadedAyahs: downloadedAyahs,
    );
  }

  Future<void> downloadSurahAudio(
    SurahDetail detail, {
    void Function(int downloadedAyahs, int totalAyahs)? onProgress,
  }) async {
    final downloadableAyahs = _downloadableAyahs(detail);
    final totalAyahs = downloadableAyahs.length;
    if (totalAyahs == 0) return;

    var downloadedAyahs = 0;
    for (final ayah in downloadableAyahs) {
      final file = await _localFileForAyah(detail.summary.number, ayah);
      if (await file.exists()) {
        downloadedAyahs++;
        onProgress?.call(downloadedAyahs, totalAyahs);
        continue;
      }

      final response = await _client.get(Uri.parse(ayah.audioUrl));
      if (response.statusCode != 200) {
        throw HttpException(
          'No se pudo descargar el audio de la aya ${ayah.numberInSurah}.',
        );
      }

      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);

      downloadedAyahs++;
      onProgress?.call(downloadedAyahs, totalAyahs);
    }
  }

  Future<void> removeSurahDownload(int surahNumber) async {
    final directory = await _surahDirectory(surahNumber);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<String?> getDownloadedAyahPath(int surahNumber, SurahAyah ayah) async {
    final file = await _localFileForAyah(surahNumber, ayah);
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  List<SurahAyah> _downloadableAyahs(SurahDetail detail) {
    return detail.ayahs.where((ayah) => ayah.audioUrl.isNotEmpty).toList();
  }

  Future<Directory> _baseDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final audioDirectory = Directory('${directory.path}${Platform.pathSeparator}quran_audio');
    if (!await audioDirectory.exists()) {
      await audioDirectory.create(recursive: true);
    }
    return audioDirectory;
  }

  Future<Directory> _surahDirectory(int surahNumber) async {
    final baseDirectory = await _baseDirectory();
    return Directory(
      '${baseDirectory.path}${Platform.pathSeparator}surah_${surahNumber.toString().padLeft(3, '0')}',
    );
  }

  Future<File> _localFileForAyah(int surahNumber, SurahAyah ayah) async {
    final surahDirectory = await _surahDirectory(surahNumber);
    return File(
      '${surahDirectory.path}${Platform.pathSeparator}ayah_${ayah.numberInSurah.toString().padLeft(3, '0')}.mp3',
    );
  }
}
