import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la disponibilidad offline de hadices
class HadithOfflineService {
  static const String _prefsKeyCollections = 'hadith_downloaded_collections';
  static const String _prefsKeyLastSync = 'hadith_last_sync';

  /// Colecciones disponibles para descarga
  static const Map<String, String> availableCollections = {
    'bukhari': 'Sahih Al-Bujari',
    'muslim': 'Sahih Muslim',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'abudawud': 'Sunan Abu Dawud',
    'ahmad': 'Musnad Ahmad',
    'malik': 'Muwatta Malik',
    'general': 'Otros Hadices',
  };

  /// Verifica si una colección está disponible offline
  Future<bool> isCollectionDownloaded(String collectionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_prefsKeyCollections) ?? [];
    return downloaded.contains(collectionKey);
  }

  /// Obtiene todas las colecciones descargadas
  Future<List<String>> getDownloadedCollections() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKeyCollections) ?? [];
  }

  /// Marca una colección como descargada (ya que los hadices ya están en assets)
  Future<void> markCollectionAsDownloaded(String collectionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_prefsKeyCollections) ?? [];
    if (!downloaded.contains(collectionKey)) {
      downloaded.add(collectionKey);
      await prefs.setStringList(_prefsKeyCollections, downloaded);
    }
  }

  /// Marca todas las colecciones como descargadas
  Future<void> markAllCollectionsAsDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyCollections,
      availableCollections.keys.toList(),
    );
    await prefs.setString(
      _prefsKeyLastSync,
      DateTime.now().toIso8601String(),
    );
  }

  /// Elimina una colección de descargadas (solo marca, los archivos permanecen)
  Future<void> removeCollection(String collectionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_prefsKeyCollections) ?? [];
    downloaded.remove(collectionKey);
    await prefs.setStringList(_prefsKeyCollections, downloaded);
  }

  /// Obtiene el estado de sincronización
  Future<HadithOfflineStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_prefsKeyCollections) ?? [];
    final lastSyncString = prefs.getString(_prefsKeyLastSync);

    DateTime? lastSync;
    if (lastSyncString != null) {
      lastSync = DateTime.tryParse(lastSyncString);
    }

    return HadithOfflineStatus(
      downloadedCollections: downloaded,
      totalCollections: availableCollections.keys.length,
      lastSync: lastSync,
      isFullyOffline: downloaded.length == availableCollections.keys.length,
    );
  }

  /// Carga hadices desde assets (siempre disponible offline)
  Future<List<dynamic>> loadCollection(String collectionKey) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/hadiths/$collectionKey.json',
      );
      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  /// Verifica si todos los hadices están disponibles offline
  Future<bool> isAllHadithsAvailable() async {
    final status = await getStatus();
    return status.isFullyOffline;
  }
}

/// Estado offline de los hadices
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
    if (lastSync == null) return 'Nunca';
    final now = DateTime.now();
    final diff = now.difference(lastSync!);

    if (diff.inDays > 0) return 'Hace ${diff.inDays} días';
    if (diff.inHours > 0) return 'Hace ${diff.inHours} horas';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} minutos';
    return 'Ahora mismo';
  }
}
