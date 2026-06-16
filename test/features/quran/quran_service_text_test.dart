import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/quran/services/quran_service.dart';

void main() {
  group('normalizeQuranArabicForDisplay', () {
    test('keeps harakat while removing iOS-problematic Uthmani glyphs', () {
      const uthmani =
          'ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ';

      final normalized = normalizeQuranArabicForDisplay(uthmani);

      expect(normalized, isNot(contains('\u0671')));
      expect(normalized, isNot(contains('\u0640')));
      expect(normalized, contains('\u064E')); // fatha
      expect(normalized, contains('\u0650')); // kasra
      expect(normalized, contains('\u0652')); // sukun
      expect(normalized, contains('\u0670')); // dagger alif
      expect(normalized, isNot(contains('\u06DB'))); // iOS missing glyph
    });
  });
}
