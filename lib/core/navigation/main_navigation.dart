import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../../features/quran/services/quran_mini_player_service.dart';
import '../../features/support/screens/dua_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QiblaScreen(),
    const DhikrScreen(),
    const DuasScreen(),
    const QuranScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final miniPlayerState = ref.watch(quranMiniPlayerControllerProvider);
    final navigationBarTheme = theme.navigationBarTheme;
    final navigationBackground =
        navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final navigationIndicator =
        navigationBarTheme.indicatorColor ??
        theme.colorScheme.primary.withOpacity(0.12);

    return Scaffold(
      body: _screens[_currentIndex],
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
                  setState(() {
                    _currentIndex = index;
                  });
                },
                height: 78,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Inicio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Qibla',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.scatter_plot_outlined),
                    selectedIcon: Icon(Icons.scatter_plot),
                    label: 'Tasbih',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.volunteer_activism_outlined),
                    selectedIcon: Icon(Icons.volunteer_activism),
                    label: 'Dua',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: 'Corán',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              '${state.surahName} · Aleya ${state.ayahNumber}',
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
            tooltip: state.isPlaying ? 'Pausar audio' : 'Reanudar audio',
          ),
        ],
      ),
    );
  }
}
