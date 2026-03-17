import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qibla_time/features/focus/services/focus_service.dart';

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _exitController;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    // Start tracking immediately when screen opens
    Future.microtask(() => ref.read(focusProvider.notifier).startFocus());

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _closeFocusMode();
        }
      });
  }

  void _closeFocusMode() {
    ref.read(focusProvider.notifier).stopFocus();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusProvider);
    // 2 prosatrations (sujood) per rak'ah
    final rakahCount = (focusState.rakahs / 2).floor();
    final remainder = focusState.rakahs % 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // DND Status Indicator
            if (focusState.dndActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.do_not_disturb_on, color: Colors.white.withOpacity(0.5), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MODO NO MOLESTAR ACTIVO',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            else
              TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.notifications_off, size: 14, color: Colors.amber),
                label: const Text(
                  'Activar No Molestar en Ajustes',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Text(
                    'RAK\'AH',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$rakahCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 160,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (remainder > 0)
                    Text(
                      '+ Sujood',
                      style: TextStyle(
                        color: Colors.teal.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            // Hold to Exit Button
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: GestureDetector(
                onLongPressStart: (_) {
                  setState(() => _isExiting = true);
                  _exitController.forward();
                },
                onLongPressEnd: (_) {
                  setState(() => _isExiting = false);
                  _exitController.reverse();
                },
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _exitController.value,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 4,
                          ),
                        ),
                        Icon(
                          Icons.power_settings_new,
                          color: Colors.white.withOpacity(_isExiting ? 1.0 : 0.4),
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Manten pulsado para salir',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
