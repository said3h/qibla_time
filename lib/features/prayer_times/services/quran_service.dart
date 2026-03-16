

class QuranVerseService {
  static final List<Map<String, String>> _verses = [
    {
      'verse': 'Indeed, prayer has been decreed upon the believers a decree of specified times.',
      'ref': 'Surah An-Nisa [4:103]'
    },
    {
      'verse': 'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
      'ref': 'Surah Al-Baqarah [2:152]'
    },
    {
      'verse': 'And seek help through patience and prayer, and indeed, it is difficult except for the humbly submissive [to Allah].',
      'ref': 'Surah Al-Baqarah [2:45]'
    },
    {
      'verse': 'Allah does not burden a soul beyond that it can bear.',
      'ref': 'Surah Al-Baqarah [2:286]'
    },
    {
      'verse': 'Indeed, with hardship [will be] ease.',
      'ref': 'Surah Ash-Sharh [94:6]'
    },
  ];

  static Map<String, String> getVerseOfTheDay() {
    // Use the day of the year as a seed so it changes daily but stays same for the day
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _verses[dayOfYear % _verses.length];
  }
}
