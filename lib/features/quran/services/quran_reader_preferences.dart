import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/settings_service.dart';

final quranTajweedEnabledProvider = FutureProvider<bool>((ref) {
  return SettingsService.instance.getQuranTajweedEnabled();
});
