import 'dart:convert';

import 'package:flutter/services.dart';

/// Servicio para gestionar la disponibilidad sin conexión de hadices
class HadithOfflineService {
  /// Colecciones incluidas dentro de la app.
  static const Map<String, String> availableCollections = {
    'bukhari': 'Sahih Al-Bujari',
    'muslim': 'Sahih Muslim',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'abudawud': 'Sunan Abu Dawud',
    'ahmad': 'Musnad Ahmad',
    'malik': 'Muwatta Malik',
    'general': 'Otros hadices',
  };

  /// Todas las colecciones están disponibles sin conexión de forma permanente.
  Future<bool> isCollectionDownloaded(String collectionKey) async {
    return availableCollections.containsKey(collectionKey);
  }

  /// Devuelve todas las colecciones incluidas en assets.
  Future<List<String>> getDownloadedCollections() async {
    return availableCollections.keys.toList();
  }

  /// No-op: los hadices ya vienen incluidos sin conexión dentro de la app.
  Future<void> markCollectionAsDownloaded(String collectionKey) async {}

  /// No-op: no existe sincronización real para hadices.
  Future<void> markAllCollectionsAsDownloaded() async {}

  /// No-op: no se elimina contenido real, ya que las colecciones están en assets.
  Future<void> removeCollection(String collectionKey) async {}

  /// Obtiene el estado real de disponibilidad sin conexión.
  Future<HadithOfflineStatus> getStatus() async {
    return HadithOfflineStatus(
      downloadedCollections: await getDownloadedCollections(),
      totalCollections: availableCollections.keys.length,
      lastSync: null,
      isFullyOffline: true,
    );
  }

  /// Carga hadices desde assets (siempre disponibles sin conexión)
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

  /// Verifica si todos los hadices están disponibles sin conexión
  Future<bool> isAllHadithsAvailable() async {
    return true;
  }
}

/// Estado sin conexión de los hadices
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
    if (lastSync == null) return 'Incluidos en la app';
    final now = DateTime.now();
    final diff = now.difference(lastSync!);

    if (diff.inDays > 0) return 'Hace ${diff.inDays} días';
    if (diff.inHours > 0) return 'Hace ${diff.inHours} horas';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} minutos';
    return 'Ahora mismo';
  }
}
