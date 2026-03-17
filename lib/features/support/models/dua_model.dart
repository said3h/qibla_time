class Dua {
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String category;
  final String? reference;

  const Dua({
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    this.reference,
  });
}
