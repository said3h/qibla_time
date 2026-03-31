class HadithShareData {
  const HadithShareData({
    this.arabicText,
    required this.translation,
    required this.reference,
    this.arabicReference,
    this.badgeLabel = 'HADITH',
    this.branding = 'App: Qibla Time',
  });

  final String? arabicText;
  final String translation;
  final String reference;
  final String? arabicReference;
  final String badgeLabel;
  final String branding;

  bool get hasArabicText => (arabicText ?? '').trim().isNotEmpty;
  bool get hasTranslation => translation.trim().isNotEmpty;
  bool get hasArabicReference => (arabicReference ?? '').trim().isNotEmpty;
}
