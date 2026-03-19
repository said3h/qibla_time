import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String prayerCacheBox = 'prayer_cache';
  static const String hadithBox = 'hadith_box';
  static const String hafizBox = 'hafiz_box';
  static const String syncBox = 'sync_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(prayerCacheBox);
    await Hive.openBox(hadithBox);
    await Hive.openBox(hafizBox);
    await Hive.openBox(syncBox);
  }
}
