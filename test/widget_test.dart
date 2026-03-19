import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/core/theme/app_theme.dart';

void main() {
  testWidgets('Navigation shell renders expected tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('QiblaTime')),
          bottomNavigationBar: NavigationBar(
            destinations: [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Qibla'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Tasbih'),
              NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), label: 'Dua'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Coran'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('QiblaTime'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Qibla'), findsOneWidget);
    expect(find.text('Tasbih'), findsOneWidget);
    expect(find.text('Dua'), findsOneWidget);
    expect(find.text('Coran'), findsOneWidget);
  });
}
