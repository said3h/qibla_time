import 'package:flutter/material.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/support/screens/dua_screen.dart';
import '../../features/quran/screens/quran_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
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
        child: NavigationBarTheme(
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
                label: 'Coran',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

