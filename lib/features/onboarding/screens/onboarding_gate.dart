import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../services/onboarding_service.dart';
import 'onboarding_screen.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  final OnboardingService _service = OnboardingService();
  late Future<bool> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _service.isCompleted();
  }

  Future<void> _handleCompleted() async {
    await _service.complete();
    if (!mounted) return;
    setState(() {
      _statusFuture = Future<bool>.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return FutureBuilder<bool>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: tokens.bgPage,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: tokens.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Preparando QiblaTime',
                    style: GoogleFonts.dmSans(
                      color: tokens.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainNavigation();
        }

        return OnboardingScreen(
          onCompleted: _handleCompleted,
          onSkipped: _handleCompleted,
        );
      },
    );
  }
}
