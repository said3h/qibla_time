import 'package:flutter/material.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/support/screens/settings_screen.dart';
import '../../features/support/screens/dua_screen.dart';
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
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        height: 78,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: AppTheme.deep,
        indicatorColor: AppTheme.primaryBg,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryGreen),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.primaryGreen),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryGreen),
            label: 'Tasbih',
          ),
          NavigationDestination(
            icon: const Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism, color: AppTheme.primaryGreen),
            label: 'Dua',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.primaryGreen),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

