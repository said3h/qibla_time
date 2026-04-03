import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';

class HadithOfflineService {
  static const Map<String, String> availableCollections = {
    'bukhari': 'Sahih Al-Bujari',
    'muslim': 'Sahih Muslim',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'abudawud': 'Sunan Abu Dawud',
    'ahmad': 'Musnad Ahmad',
    'malik': 'Muwatta Malik',
    'general': 'Otros hadices',
  };

  Future<bool> isCollectionDownloaded(String collectionKey) async {
    return availableCollections.containsKey(collectionKey);
  }

  Future<List<String>> getDownloadedCollections() async {
    return availableCollections.keys.toList();
  }

  Future<void> markCollectionAsDownloaded(String collectionKey) async {}

  Future<void> markAllCollectionsAsDownloaded() async {}

  Future<void> removeCollection(String collectionKey) async {}

  Future<HadithOfflineStatus> getStatus() async {
    return HadithOfflineStatus(
      downloadedCollections: await getDownloadedCollections(),
      totalCollections: availableCollections.keys.length,
      lastSync: null,
      isFullyOffline: true,
    );
  }

  Future<List<dynamic>> loadCollection(String collectionKey) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/hadiths/$collectionKey.json',
      );
      return json.decode(jsonString) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  Future<bool> isAllHadithsAvailable() async {
    return true;
  }
}

class HadithOfflineStatus {
  const HadithOfflineStatus({
    required this.downloadedCollections,
    required this.totalCollections,
    required this.lastSync,
    required this.isFullyOffline,
  });

  final List<String> downloadedCollections;
  final int totalCollections;
  final DateTime? lastSync;
  final bool isFullyOffline;

  int get downloadedCount => downloadedCollections.length;
  double get downloadProgress => downloadedCount / totalCollections;

  String get lastSyncLabel {
    final l10n = appLocalizationsForCurrentLocale();
    if (lastSync == null) return l10n.hadithOfflineIncludedInApp;

    final now = DateTime.now();
    final diff = now.difference(lastSync!);

    if (diff.inDays > 0) {
      return l10n.hadithOfflineAgoDays(diff.inDays);
    }
    if (diff.inHours > 0) {
      return l10n.hadithOfflineAgoHours(diff.inHours);
    }
    if (diff.inMinutes > 0) {
      return l10n.hadithOfflineAgoMinutes(diff.inMinutes);
    }
    return l10n.hadithOfflineNow;
  }
}
