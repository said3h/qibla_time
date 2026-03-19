class Hadith {
  const Hadith({
    required this.id,
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.category,
    required this.grade,
  });

  final int id;
  final String arabic;
  final String translation;
  final String reference;
  final String category;
  final String grade;

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int,
      arabic: json['arabic'] as String,
      translation: json['translation'] as String,
      reference: json['reference'] as String,
      category: json['category'] as String,
      grade: json['grade'] as String,
    );
  }
}
