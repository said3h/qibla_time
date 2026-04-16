import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/locale_controller.dart';
import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/prayer_times/services/adhan_manager.dart';
import '../../features/prayer_times/services/travel_mode_service.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../../features/quran/services/quran_mini_player_service.dart';
import '../../features/support/screens/dua_screen.dart';
import '../../l10n/l10n.dart';
import '../theme/theme_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with WidgetsBindingObserver {
  static const _foregroundRefreshCooldown = Duration(seconds: 12);

  int _currentIndex = 0;
  DateTime? _lastForegroundRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    final now = DateTime.now();
    final lastRefreshAt = _lastForegroundRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _foregroundRefreshCooldown) {
      return;
    }

    _lastForegroundRefreshAt = now;
    _refreshLocationDrivenState();
    // Reprogramar adhans al volver al frente: cubre el caso de que la app haya
    // cruzado la medianoche en segundo plano y necesite el horario del nuevo día.
    ref.read(adhanManagerProvider).scheduleTodayAdhans();
  }

  void _refreshLocationDrivenState() {
    ref.invalidate(prayerLocationProvider);
    ref.invalidate(prayerLocationDiagnosticProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(nextPrayerInfoProvider);
    ref.invalidate(prayerCountdownProvider);
    ref.invalidate(lastLocationLabelProvider);
    ref.invalidate(recentLocationsProvider);
    ref.invalidate(travelBannerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeName = ref.watch(themeControllerProvider);
    final theme = Theme.of(context);
    final miniPlayerState = ref.watch(quranMiniPlayerControllerProvider);
    final currentLanguageCode = ref.watch(currentLanguageCodeProvider);
    final navigationBarTheme = theme.navigationBarTheme;
    final navigationBackground =
        navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final navigationIndicator =
        navigationBarTheme.indicatorColor ??
        theme.colorScheme.primary.withOpacity(0.12);

    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey('$_currentIndex-$themeName'),
        child: _buildScreenForIndex(_currentIndex),
      ),
      bottomNavigationBar: Material(
        color: navigationBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (miniPlayerState.isVisible)
              _QuranMiniPlayerBar(
                state: miniPlayerState,
                onTogglePlayPause: () {
                  ref
                      .read(quranMiniPlayerControllerProvider.notifier)
                      .togglePlayPause();
                },
              ),
            NavigationBarTheme(
              data: navigationBarTheme.copyWith(
                backgroundColor: navigationBackground,
                indicatorColor: navigationIndicator,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: NavigationBar(
                backgroundColor: navigationBackground,
                indicatorColor: navigationIndicator,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  if (index == 0 && _currentIndex == 0) {
                    ref.read(homeScrollToTopSignalProvider.notifier).state++;
                    return;
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                height: 78,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: l10n.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    label: l10n.navQibla,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.scatter_plot_outlined),
                    selectedIcon: const Icon(Icons.scatter_plot),
                    label: l10n.navTasbih,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.volunteer_activism_outlined),
                    selectedIcon: const Icon(Icons.volunteer_activism),
                    label: l10n.navDua,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book),
                    label: l10n.navQuran,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const QiblaScreen();
      case 2:
        return const DhikrScreen();
      case 3:
        return const DuasScreen();
      case 4:
        return const QuranScreen();
      default:
        return const HomeScreen();
    }
  }
}

class _QuranMiniPlayerBar extends StatelessWidget {
  const _QuranMiniPlayerBar({
    required this.state,
    required this.onTogglePlayPause,
  });

  final QuranMiniPlayerState state;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              currentLanguageCode == 'ar'
                  ? '${state.surahName} · الآية ${state.ayahNumber}'
                  : l10n.navigationMiniPlayerAyah(
                      state.surahName,
                      state.ayahNumber,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onTogglePlayPause,
            icon: Icon(
              state.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
            ),
            tooltip: state.isPlaying
                ? l10n.quranPauseAudio
                : l10n.quranResumeAudio,
          ),
        ],
      ),
    );
  }
}
