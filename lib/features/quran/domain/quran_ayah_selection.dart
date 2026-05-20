enum QuranAyahSelectionDecisionType {
  add,
  remove,
  rejectNonConsecutive,
  rejectMaxReached,
}

class QuranAyahSelectionDecision {
  const QuranAyahSelectionDecision({
    required this.type,
    required this.selectedAyahs,
  });

  final QuranAyahSelectionDecisionType type;
  final Set<int> selectedAyahs;

  bool get accepted =>
      type == QuranAyahSelectionDecisionType.add ||
      type == QuranAyahSelectionDecisionType.remove;
}

QuranAyahSelectionDecision toggleContiguousAyahSelection({
  required Set<int> selectedAyahs,
  required int ayahNumber,
  required int maxSelectedAyahs,
}) {
  final nextSelection = Set<int>.from(selectedAyahs);

  if (nextSelection.isEmpty) {
    nextSelection.add(ayahNumber);
    return QuranAyahSelectionDecision(
      type: QuranAyahSelectionDecisionType.add,
      selectedAyahs: nextSelection,
    );
  }

  final rangeStart = nextSelection.reduce(
    (value, element) => value < element ? value : element,
  );
  final rangeEnd = nextSelection.reduce(
    (value, element) => value > element ? value : element,
  );

  if (nextSelection.contains(ayahNumber)) {
    final isRangeEdge = ayahNumber == rangeStart || ayahNumber == rangeEnd;
    if (!isRangeEdge && nextSelection.length > 1) {
      return QuranAyahSelectionDecision(
        type: QuranAyahSelectionDecisionType.rejectNonConsecutive,
        selectedAyahs: nextSelection,
      );
    }

    nextSelection.remove(ayahNumber);
    return QuranAyahSelectionDecision(
      type: QuranAyahSelectionDecisionType.remove,
      selectedAyahs: nextSelection,
    );
  }

  final canExtendRange =
      ayahNumber == rangeStart - 1 || ayahNumber == rangeEnd + 1;
  if (!canExtendRange) {
    return QuranAyahSelectionDecision(
      type: QuranAyahSelectionDecisionType.rejectNonConsecutive,
      selectedAyahs: nextSelection,
    );
  }

  if (nextSelection.length >= maxSelectedAyahs) {
    return QuranAyahSelectionDecision(
      type: QuranAyahSelectionDecisionType.rejectMaxReached,
      selectedAyahs: nextSelection,
    );
  }

  nextSelection.add(ayahNumber);
  return QuranAyahSelectionDecision(
    type: QuranAyahSelectionDecisionType.add,
    selectedAyahs: nextSelection,
  );
}
