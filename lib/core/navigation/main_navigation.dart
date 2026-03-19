import 'package:flutter/material.dart';
import '../../features/prayer_times/screens/home_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/dhikr/screens/dhikr_screen.dart';
import '../../features/support/screens/support_screen.dart';
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
    const CalendarScreen(),
    const DhikrScreen(),
    const SupportScreen(),
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
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryGreen.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled, color: AppTheme.primaryGreen),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.primaryGreen),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined), // Using this for Tasbih/Dhikr feeling
            selectedIcon: Icon(Icons.volunteer_activism, color: AppTheme.primaryGreen),
            label: 'Dhikr',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.primaryGreen),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}

