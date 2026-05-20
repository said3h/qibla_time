import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/quran/domain/quran_ayah_selection.dart';

void main() {
  group('toggleContiguousAyahSelection', () {
    test('starts selection with tapped ayah', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: const {},
        ayahNumber: 3,
        maxSelectedAyahs: 5,
      );

      expect(decision.type, QuranAyahSelectionDecisionType.add);
      expect(decision.selectedAyahs, {3});
    });

    test('extends selection only from range edges', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: {3},
        ayahNumber: 4,
        maxSelectedAyahs: 5,
      );

      expect(decision.type, QuranAyahSelectionDecisionType.add);
      expect(decision.selectedAyahs, {3, 4});
    });

    test('rejects non-consecutive ayahs', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: {2, 3, 4},
        ayahNumber: 6,
        maxSelectedAyahs: 5,
      );

      expect(
        decision.type,
        QuranAyahSelectionDecisionType.rejectNonConsecutive,
      );
      expect(decision.selectedAyahs, {2, 3, 4});
    });

    test('allows removing a range edge', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: {2, 3, 4},
        ayahNumber: 2,
        maxSelectedAyahs: 5,
      );

      expect(decision.type, QuranAyahSelectionDecisionType.remove);
      expect(decision.selectedAyahs, {3, 4});
    });

    test('rejects removing an ayah from the middle of a range', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: {2, 3, 4},
        ayahNumber: 3,
        maxSelectedAyahs: 5,
      );

      expect(
        decision.type,
        QuranAyahSelectionDecisionType.rejectNonConsecutive,
      );
      expect(decision.selectedAyahs, {2, 3, 4});
    });

    test('rejects extending beyond the max selection size', () {
      final decision = toggleContiguousAyahSelection(
        selectedAyahs: {1, 2, 3, 4, 5},
        ayahNumber: 6,
        maxSelectedAyahs: 5,
      );

      expect(decision.type, QuranAyahSelectionDecisionType.rejectMaxReached);
      expect(decision.selectedAyahs, {1, 2, 3, 4, 5});
    });
  });
}
