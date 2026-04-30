class AyahShareData {
  const AyahShareData({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.ayahNumber,
    this.endAyahNumber,
    required this.arabicText,
    this.translation,
    this.badgeLabel = 'QURAN',
    this.branding = 'QIBLA TIME',
  });

  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int ayahNumber;
  final int? endAyahNumber;
  final String arabicText;
  final String? translation;
  final String badgeLabel;
  final String branding;

  bool get hasArabicText => arabicText.trim().isNotEmpty;
  bool get hasTranslation => (translation ?? '').trim().isNotEmpty;

  String get _ayahRange => endAyahNumber == null || endAyahNumber == ayahNumber
      ? '$ayahNumber'
      : '$ayahNumber\u2013$endAyahNumber';

  String get _arabicAyahRange => endAyahNumber == null ||
          endAyahNumber == ayahNumber
      ? _toArabicDigits(ayahNumber)
      : '${_toArabicDigits(ayahNumber)}\u2013${_toArabicDigits(endAyahNumber!)}';

  String get referenceLabel => '$surahNameLatin $surahNumber:$_ayahRange';
  String get arabicReferenceLabel =>
      '$surahNameArabic ${_toArabicDigits(surahNumber)}:$_arabicAyahRange';

  String _toArabicDigits(int value) {
    const westernDigits = '0123456789';
    const arabicDigits =
        '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
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
