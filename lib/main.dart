import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_controller.dart';
import 'core/services/logger_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/accessibility_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/l10n.dart';

import 'features/onboarding/screens/onboarding_gate.dart';
import 'features/prayer_times/services/adhan_manager.dart';
import 'features/prayer_times/services/notification_service.dart';
import 'features/prayer_times/services/widget_sync_service.dart';
import 'features/tafsir/screens/tafsir_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _prepareCriticalStartup();

  // Ensure prayer notifications get scheduled even if the user stays in
  // onboarding (clean install) and never reaches HomeScreen yet.
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QiblaTimeApp(),
    ),
  );

  // Don't block app startup on plugin initialization, location or permissions.
  // This keeps iOS resilient if a native plugin throws before the first frame.
  Future<void>(() async {
    await _runStartupTask(
      'NotificationService.initialize',
      NotificationService.instance.initialize,
    );
    await _runStartupTask(
      'WidgetSyncService.configure',
      WidgetSyncService().configure,
    );
    await _runStartupTask(
      'AdhanManager.scheduleTodayAdhans',
      () => container.read(adhanManagerProvider).scheduleTodayAdhans(),
    );
  });
}

Future<void> _prepareCriticalStartup() async {
  await _runStartupTask('StorageService.init', StorageService.init);
  await _runStartupTask('AppLocaleController.prime', AppLocaleController.prime);
}

Future<void> _runStartupTask(
  String name,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (e, st) {
    AppLogger.error('$name failed during startup', error: e, stackTrace: st);
  }
}

class QiblaTimeApp extends ConsumerWidget {
  const QiblaTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeName = ref.watch(themeControllerProvider);
    final appLocale = ref.watch(appLocaleControllerProvider);
    final accessibility = ref.watch(accessibilityControllerProvider);
    var tokens = QiblaThemes.fromName(themeName);
    if (accessibility.highContrast) {
      tokens = tokens.copyWith(
        bgSurface: Color.alphaBlend(
          tokens.primary.withValues(alpha: 0.06),
          tokens.bgSurface,
        ),
        border: tokens.primary.withValues(alpha: 0.42),
        textSecondary: tokens.textPrimary,
        textMuted: tokens.textSecondary,
      );
    }
    QiblaThemes.currentName = themeName;

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.buildTheme(tokens),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final textScale =
            mediaQuery.textScaler.scale(1) * accessibility.fontScale;
        final effectiveBold =
            accessibility.useSystemBoldText ? mediaQuery.boldText : false;
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
            boldText: effectiveBold,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const OnboardingGate(),
      routes: {
        if (kDebugMode)
          TafsirDebugScreen.routeName: (_) => const TafsirDebugScreen(),
      },
    );
  }
}
