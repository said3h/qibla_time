class HafizProgress {
  const HafizProgress({
    required this.surahNumber,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.targetRepetitions,
    required this.completedRepetitions,
    required this.nextReviewAt,
    required this.updatedAt,
  });

  final int surahNumber;
  final String surahName;
  final int startAyah;
  final int endAyah;
  final int targetRepetitions;
  final int completedRepetitions;
  final DateTime nextReviewAt;
  final DateTime updatedAt;

  double get completion => targetRepetitions == 0 ? 0 : completedRepetitions / targetRepetitions;

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'startAyah': startAyah,
        'endAyah': endAyah,
        'targetRepetitions': targetRepetitions,
        'completedRepetitions': completedRepetitions,
        'nextReviewAt': nextReviewAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory HafizProgress.fromJson(Map<String, dynamic> json) {
    return HafizProgress(
      surahNumber: json['surahNumber'] as int,
      surahName: json['surahName'] as String,
      startAyah: json['startAyah'] as int,
      endAyah: json['endAyah'] as int,
      targetRepetitions: json['targetRepetitions'] as int,
      completedRepetitions: json['completedRepetitions'] as int,
      nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  HafizProgress copyWith({
    int? surahNumber,
    String? surahName,
    int? startAyah,
    int? endAyah,
    int? targetRepetitions,
    int? completedRepetitions,
    DateTime? nextReviewAt,
    DateTime? updatedAt,
  }) {
    return HafizProgress(
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      completedRepetitions: completedRepetitions ?? this.completedRepetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
