import 'package:flutter/material.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/support/screens/dua_screen.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../theme/app_theme.dart';

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
    final tokens = QiblaThemes.current;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: tokens.bgApp,
          indicatorColor: tokens.primaryBg,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return IconThemeData(
              color: selected ? tokens.primary : tokens.textMuted,
            );
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return TextStyle(
              color: selected ? tokens.primary : tokens.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
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
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
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
    );
  }
}

