class Dua {
  final String id;
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String category;
  final String? reference;
  final bool isFeatured;

  const Dua({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    this.reference,
    this.isFeatured = false,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      title: json['title'] as String,
      arabicText: json['arabicText'] as String,
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      category: json['category'] as String,
      reference: json['reference'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }
}
