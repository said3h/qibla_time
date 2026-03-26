class AllahName {
  const AllahName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final int id;
  final String arabic;
  final String transliteration;
  final String meaning;

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      id: json['id'] as int,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
    );
  }
}
