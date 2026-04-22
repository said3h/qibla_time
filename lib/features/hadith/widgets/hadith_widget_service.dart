import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/services/logger_service.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';

/// Servicio para sincronizar el hadiz del día con el widget de Home Screen
class HadithWidgetService {
  static const appGroupId = 'group.com.qiblatime.shared';
  static const iOSWidgetName = 'QiblaTimeHadithWidget';
  static const androidWidgetName = 'HadithWidgetProvider';

  /// Configura el widget (debe llamarse al iniciar la app)
  Future<void> configure() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Sincroniza el hadiz del día con el widget
  Future<void> syncDailyHadith(HadithSnapshot snapshot) async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('hadith_arabic', snapshot.arabic),
      HomeWidget.saveWidgetData<String>(
          'hadith_translation', snapshot.translation),
      HomeWidget.saveWidgetData<String>('hadith_reference', snapshot.reference),
      HomeWidget.saveWidgetData<String>('hadith_grade', snapshot.grade),
      HomeWidget.saveWidgetData<String>(
          'hadith_collection', snapshot.collection),
    ]);
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }

  /// Obtiene el snapshot del hadiz del día para el widget
  static Future<HadithSnapshot?> getDailyHadithSnapshot(
    HadithService hadithService,
    String? languageCode,
  ) async {
    try {
      final hadith = await hadithService.getHadithOfDay(
        forcedLanguage: languageCode,
      );
      if (hadith == null) return null;

      return snapshotFromHadith(hadith);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'HadithWidgetService.getDailyHadithSnapshot failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static HadithSnapshot snapshotFromHadith(Hadith hadith) {
    return HadithSnapshot(
      arabic: hadith.arabic.length > 150
          ? hadith.arabic.substring(0, 147) + '...'
          : hadith.arabic,
      translation: hadith.translation.length > 200
          ? hadith.translation.substring(0, 197) + '...'
          : hadith.translation,
      reference: _shortenReference(hadith.reference),
      grade: hadith.grade,
      collection: _extractCollection(hadith.reference),
    );
  }

  static String _shortenReference(String reference) {
    if (reference.length > 40) {
      return reference.substring(0, 37) + '...';
    }
    return reference;
  }

  static String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari'))
      return 'Bukhari';
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud'))
      return 'Abu Dawud';
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah'))
      return 'Ibn Majah';
    if (refLower.contains('malik') || refLower.contains('muwatta'))
      return 'Malik';
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Hadiz';
  }
}

/// Snapshot inmutable para el widget
class HadithSnapshot {
  const HadithSnapshot({
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.grade,
    required this.collection,
  });

  final String arabic;
  final String translation;
  final String reference;
  final String grade;
  final String collection;
}

final hadithWidgetServiceProvider = Provider<HadithWidgetService>((ref) {
  return HadithWidgetService();
});

/// Provider que obtiene el snapshot del hadiz del día
final dailyHadithSnapshotProvider =
    FutureProvider<HadithSnapshot?>((ref) async {
  final hadith = await ref.watch(dailyHadithProvider.future);
  if (hadith == null) {
    return null;
  }

  return HadithWidgetService.snapshotFromHadith(hadith);
});
