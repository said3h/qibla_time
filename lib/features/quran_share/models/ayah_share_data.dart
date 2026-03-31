class AyahShareData {
  const AyahShareData({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.arabicText,
    this.translation,
    this.badgeLabel = 'QURAN',
    this.branding = 'App: Qibla Time',
  });

  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int ayahNumber;
  final String arabicText;
  final String? translation;
  final String badgeLabel;
  final String branding;

  bool get hasArabicText => arabicText.trim().isNotEmpty;
  bool get hasTranslation => (translation ?? '').trim().isNotEmpty;

  String get referenceLabel => '$surahNameLatin ($surahNumber:$ayahNumber)';
  String get arabicReferenceLabel =>
      '$surahNameArabic ${_toArabicDigits(surahNumber)}:${_toArabicDigits(ayahNumber)}';

  String _toArabicDigits(int value) {
    const westernDigits = '0123456789';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final raw = '$value';
    final buffer = StringBuffer();

    for (final codeUnit in raw.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final digitIndex = westernDigits.indexOf(char);
      buffer.write(
        digitIndex == -1 ? char : arabicDigits[digitIndex],
      );
    }

    return buffer.toString();
  }
}
