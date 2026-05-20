import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String prayerCacheBox = 'prayer_cache';
  static const String hadithBox = 'hadith_box';
  static const String hafizBox = 'hafiz_box';
  static const String syncBox = 'sync_box';

  static SharedPreferences? _sharedPreferences;

  static Future<SharedPreferences> get prefs async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    await Hive.openBox(prayerCacheBox);
    await Hive.openBox(hadithBox);
    await Hive.openBox(hafizBox);
    await Hive.openBox(syncBox);
  }

  static void resetPrefsForTesting() {
    _sharedPreferences = null;
  }
}
