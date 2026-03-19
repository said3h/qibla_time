import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String prayerCacheBox = 'prayer_cache';
  static const String hadithBox = 'hadith_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(prayerCacheBox);
    await Hive.openBox(hadithBox);
  }
}
