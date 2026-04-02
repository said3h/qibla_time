import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_controller.dart';
import 'core/services/storage_service.dart';
import 'core/theme/accessibility_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/l10n.dart';

import 'features/onboarding/screens/onboarding_gate.dart';
import 'features/prayer_times/services/notification_service.dart';
import 'features/prayer_times/services/widget_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await AppLocaleController.prime();
  await NotificationService.instance.initialize();
  await WidgetSyncService().configure();
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
    final appLocale = ref.watch(appLocaleControllerProvider);
    final accessibility = ref.watch(accessibilityControllerProvider);
    var tokens = QiblaThemes.fromName(themeName);
    if (accessibility.highContrast) {
      tokens = tokens.copyWith(
        bgSurface: Color.alphaBlend(tokens.primary.withOpacity(0.06), tokens.bgSurface),
        border: tokens.primary.withOpacity(0.42),
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
        final textScale = mediaQuery.textScaler.scale(1) * accessibility.fontScale;
        final effectiveBold = accessibility.useSystemBoldText ? mediaQuery.boldText : false;
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
            boldText: effectiveBold,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const OnboardingGate(),
    );
  }
}
