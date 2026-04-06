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
    'Bukhari',
    'Muslim',
    'Tirmidhi',
    'Abu Dawud',
    'Nasai',
    'Ibn Majah',
    'Malik',
    'Ahmad',
    'Otros',
  ];

  static const _icons = <String, IconData>{
    'Bukhari': Icons.auto_stories_outlined,
    'Muslim': Icons.book_outlined,
    'Tirmidhi': Icons.menu_book_outlined,
    'Abu Dawud': Icons.library_books_outlined,
    'Nasai': Icons.import_contacts_outlined,
    'Ibn Majah': Icons.chrome_reader_mode_outlined,
    'Malik': Icons.collections_bookmark_outlined,
    'Ahmad': Icons.history_edu_outlined,
    'Otros': Icons.more_horiz_outlined,
  };

  static const _arabicLabels = <String, String>{
    'Bukhari': 'البخاري',
    'Muslim': 'مسلم',
    'Tirmidhi': 'الترمذي',
    'Abu Dawud': 'أبو داود',
    'Nasai': 'النسائي',
    'Ibn Majah': 'ابن ماجه',
    'Malik': 'مالك',
    'Ahmad': 'أحمد',
    'Otros': 'أخرى',
  };

  static HadithCollectionMeta metaFor(String collection, String languageCode) {
    final normalizedCollection = _normalizeCollection(collection);
    final normalizedLanguage = switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      _ => 'default',
    };

    final label = normalizedCollection == 'Otros'
        ? switch (normalizedLanguage) {
            'ar' => _arabicLabels[normalizedCollection] ?? normalizedCollection,
            'en' => 'Other',
            'fr' => 'Autres',
            _ => 'Otros',
          }
        : (normalizedLanguage == 'ar'
              ? (_arabicLabels[normalizedCollection] ?? normalizedCollection)
              : normalizedCollection);

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
        return 'Bukhari';
      case 'muslim':
        return 'Muslim';
      case 'tirmidhi':
        return 'Tirmidhi';
      case 'abu dawud':
        return 'Abu Dawud';
      case 'nasai':
        return 'Nasai';
      case 'ibn majah':
        return 'Ibn Majah';
      case 'malik':
        return 'Malik';
      case 'ahmad':
        return 'Ahmad';
      case 'other':
      case 'otros':
        return 'Otros';
      default:
        return collection;
    }
  }
}
