import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/quran/models/quran_models.dart';
import 'package:qibla_time/features/quran/services/quran_reading_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranReadingService', () {
    late QuranReadingService service;
    const summary = SurahSummary(
      number: 2,
      nameArabic: 'البقرة',
      nameLatin: 'Al-Baqarah',
      revelationType: 'Medinan',
      ayahCount: 286,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = QuranReadingService();
    });

    test('guarda y recupera la ultima lectura', () async {
      await service.saveLastReading(summary, 5);

      final lastReading = await service.getLastReading();

      expect(lastReading, isNotNull);
      expect(lastReading!.surahNumber, 2);
      expect(lastReading.ayahNumber, 5);
      expect(lastReading.surahNameLatin, 'Al-Baqarah');
    });

    test('anade y elimina bookmarks simples', () async {
      final saved = await service.toggleBookmark(summary, 12);
      final bookmarksAfterSave = await service.getBookmarks();
      final removed = await service.toggleBookmark(summary, 12);
      final bookmarksAfterRemove = await service.getBookmarks();

      expect(saved, isTrue);
      expect(bookmarksAfterSave, hasLength(1));
      expect(bookmarksAfterSave.first.ayahNumber, 12);
      expect(removed, isFalse);
      expect(bookmarksAfterRemove, isEmpty);
    });
  });
}
