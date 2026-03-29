class ReligiousReferenceFormatter {
  static String? buildArabicReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final segments = trimmed
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return null;

    final converted = <String>[];
    for (final segment in segments) {
      final arabicSegment = _buildArabicReferenceSegment(segment);
      if (arabicSegment == null) {
        return null;
      }
      converted.add(arabicSegment);
    }

    return converted.join('، ');
  }

  static String toArabicDigits(String value) {
    const westernDigits = '0123456789';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();

    for (final codeUnit in value.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final digitIndex = westernDigits.indexOf(char);
      buffer.write(digitIndex == -1 ? char : arabicDigits[digitIndex]);
    }

    return buffer.toString();
  }

  static String? _buildArabicReferenceSegment(String segment) {
    final normalized = segment
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[-‐‑‒–—]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    final locatorPattern = RegExp(r'^[0-9:.\-–]+$');
    final entries = <({List<String> aliases, String arabicName})>[
      (
        aliases: [
          'sahih al bukhari',
          'sahih bukhari',
          'al bukhari',
          'bukhari',
          'bujari',
        ],
        arabicName: 'البخاري',
      ),
      (
        aliases: [
          'sahih muslim',
          'muslim',
        ],
        arabicName: 'مسلم',
      ),
      (
        aliases: [
          'jami at tirmidhi',
          'jami al tirmidhi',
          'sunan al tirmidhi',
          'sunan at tirmidhi',
          'tirmidhi',
        ],
        arabicName: 'الترمذي',
      ),
      (
        aliases: [
          'sunan abi dawud',
          'sunan abu dawud',
          'abu dawud',
          'abudawud',
        ],
        arabicName: 'أبو داود',
      ),
      (
        aliases: [
          'sunan an nasai',
          'sunan al nasai',
          'an nasai',
          'al nasai',
          'nasai',
        ],
        arabicName: 'النسائي',
      ),
      (
        aliases: [
          'sunan ibn majah',
          'ibn majah',
        ],
        arabicName: 'ابن ماجه',
      ),
      (
        aliases: [
          'muwatta malik',
          'malik',
        ],
        arabicName: 'مالك',
      ),
      (
        aliases: [
          'musnad ahmad',
          'ahmad',
        ],
        arabicName: 'أحمد',
      ),
      (
        aliases: [
          'sahih ibn hibban',
          'ibn hibban',
        ],
        arabicName: 'ابن حبان',
      ),
      (
        aliases: [
          'quran',
        ],
        arabicName: 'القرآن',
      ),
    ];

    for (final entry in entries) {
      for (final alias in entry.aliases) {
        if (!normalized.startsWith('$alias ')) continue;

        final locator = normalized.substring(alias.length).trim();
        if (locator.isEmpty || !locatorPattern.hasMatch(locator)) {
          return null;
        }

        return '${entry.arabicName} ${toArabicDigits(locator)}';
      }
    }

    return null;
  }
}
