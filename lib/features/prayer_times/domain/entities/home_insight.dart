enum HomeInsightKind {
  progress,
  streak,
  improvement,
  prayerPattern,
  dhikr,
  ramadan,
  guidance,
}

class HomeInsight {
  const HomeInsight({
    required this.kind,
    required this.title,
    required this.message,
  });

  final HomeInsightKind kind;
  final String title;
  final String message;
}

class HomeInsightBundle {
  const HomeInsightBundle({
    required this.primary,
    this.secondary,
  });

  final HomeInsight primary;
  final HomeInsight? secondary;
}
