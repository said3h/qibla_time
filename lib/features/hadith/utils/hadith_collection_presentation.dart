import 'package:flutter/material.dart';

class HadithCollectionMeta {
  const HadithCollectionMeta({
    required this.icon,
    required this.label,
    required this.arabicLabel,
  });

  final IconData icon;
  final String label;
  final String arabicLabel;
}

class HadithCollectionPresentation {
  static const orderedCollections = <String>[
    'Sahih al-Bukhari',
    'Sahih Muslim',
    'Riyad as-Salihin',
    '40 Hadith Nawawi',
    'Sunan Abu Dawud',
    'Jami\' at-Tirmidhi',
    'Sunan an-Nasa\'i',
    'Sunan Ibn Majah',
    'Muwatta Malik',
    'Otros',
  ];

  static const _icons = <String, IconData>{
    'Sahih al-Bukhari': Icons.auto_stories_outlined,
    'Sahih Muslim': Icons.book_outlined,
    'Riyad as-Salihin': Icons.local_florist_outlined,
    '40 Hadith Nawawi': Icons.format_list_numbered_outlined,
    'Sunan Abu Dawud': Icons.library_books_outlined,
    'Jami\' at-Tirmidhi': Icons.menu_book_outlined,
    'Sunan an-Nasa\'i': Icons.import_contacts_outlined,
    'Sunan Ibn Majah': Icons.chrome_reader_mode_outlined,
    'Muwatta Malik': Icons.collections_bookmark_outlined,
    'Otros': Icons.more_horiz_outlined,
  };

  static const _arabicLabels = <String, String>{
    'Sahih al-Bukhari': 'صحيح البخاري',
    'Sahih Muslim': 'صحيح مسلم',
    'Riyad as-Salihin': 'رياض الصالحين',
    '40 Hadith Nawawi': 'الأربعون النووية',
    'Sunan Abu Dawud': 'سنن أبي داود',
    'Jami\' at-Tirmidhi': 'جامع الترمذي',
    'Sunan an-Nasa\'i': 'سنن النسائي',
    'Sunan Ibn Majah': 'سنن ابن ماجه',
    'Muwatta Malik': 'موطأ مالك',
    'Otros': 'أخرى',
  };

  static const _russianLabels = <String, String>{
    'Sahih al-Bukhari': 'Сахих аль-Бухари',
    'Sahih Muslim': 'Сахих Муслим',
    'Riyad as-Salihin': 'Рияд ас-Салихин',
    '40 Hadith Nawawi': '40 хадисов ан-Навави',
    'Sunan Abu Dawud': 'Сунан Абу Дауда',
    'Jami\' at-Tirmidhi': 'Джами ат-Тирмизи',
    'Sunan an-Nasa\'i': 'Сунан ан-Насаи',
    'Sunan Ibn Majah': 'Сунан Ибн Маджи',
    'Muwatta Malik': 'Муватта Малик',
    'Otros': 'Другие',
  };

  static HadithCollectionMeta metaFor(String collection, String languageCode) {
    final normalizedCollection = _normalizeCollection(collection);
    final normalizedLanguage = switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      'ru' => 'ru',
      _ => 'default',
    };

    final label = normalizedCollection == 'Otros'
        ? switch (normalizedLanguage) {
            'ar' => _arabicLabels[normalizedCollection] ?? normalizedCollection,
            'en' => 'Other',
            'fr' => 'Autres',
            'ru' => _russianLabels[normalizedCollection] ?? 'Другие',
            _ => 'Otros',
          }
        : switch (normalizedLanguage) {
            'ar' => _arabicLabels[normalizedCollection] ?? normalizedCollection,
            'ru' => _russianLabels[normalizedCollection] ?? normalizedCollection,
            _ => normalizedCollection,
          };

    return HadithCollectionMeta(
      icon: _icons[normalizedCollection] ?? Icons.auto_stories_outlined,
      label: label,
      arabicLabel: _arabicLabels[normalizedCollection] ?? '',
    );
  }

  static String _normalizeCollection(String collection) {
    final value = collection.trim().toLowerCase();
    switch (value) {
      case 'bukhari':
      case 'boukhari':
      case 'sahih al-bukhari':
        return 'Sahih al-Bukhari';
      case 'muslim':
      case 'mouslim':
      case 'sahih muslim':
        return 'Sahih Muslim';
      case 'riyad':
      case 'salihin':
      case 'riyad as-salihin':
        return 'Riyad as-Salihin';
      case 'nawawi':
      case '40 hadith nawawi':
        return '40 Hadith Nawawi';
      case 'abu dawud':
      case 'abou dawoud':
      case 'sunan abu dawud':
        return 'Sunan Abu Dawud';
      case 'tirmidhi':
      case 'jami\' at-tirmidhi':
        return 'Jami\' at-Tirmidhi';
      case 'nasai':
      case 'nasa\'i':
      case 'sunan an-nasa\'i':
        return 'Sunan an-Nasa\'i';
      case 'ibn majah':
      case 'sunan ibn majah':
        return 'Sunan Ibn Majah';
      case 'malik':
      case 'muwatta malik':
        return 'Muwatta Malik';
      case 'other':
      case 'otros':
        return 'Otros';
      default:
        return collection;
    }
  }
}
