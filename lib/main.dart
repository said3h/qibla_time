import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/navigation/main_navigation.dart';

import 'features/prayer_times/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: QiblaTimeApp(),
    ),
  );
}

class QiblaTimeApp extends ConsumerWidget {
  const QiblaTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeName = ref.watch(themeControllerProvider);
    final tokens = QiblaThemes.fromName(themeName);
    QiblaThemes.currentName = themeName;

    return MaterialApp(
      title: 'QiblaTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(tokens),
      home: const MainNavigation(),
    );
  }
}
