class AyahShareData {
  const AyahShareData({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.ayahNumber,
    required this.arabicText,
    this.translation,
    this.branding = 'Qibla',
  });

  final int surahNumber;
  final String surahNameLatin;
  final int ayahNumber;
  final String arabicText;
  final String? translation;
  final String branding;

  bool get hasArabicText => arabicText.trim().isNotEmpty;
  bool get hasTranslation => (translation ?? '').trim().isNotEmpty;

  String get referenceLabel => '$surahNameLatin ($surahNumber:$ayahNumber)';
}
