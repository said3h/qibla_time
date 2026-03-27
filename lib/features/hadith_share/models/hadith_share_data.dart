class HadithShareData {
  const HadithShareData({
    this.arabicText,
    required this.translation,
    required this.reference,
    this.branding = 'Qibla',
  });

  final String? arabicText;
  final String translation;
  final String reference;
  final String branding;

  bool get hasArabicText => (arabicText ?? '').trim().isNotEmpty;
}
