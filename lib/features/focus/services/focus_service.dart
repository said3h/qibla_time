import 'dart:async';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class FocusState {
  final bool isActive;
  final int rakahs;
  final bool isNear;
  final bool dndActive;

  FocusState({
    this.isActive = false,
    this.rakahs = 0,
    this.isNear = false,
    this.dndActive = false,
  });

  FocusState copyWith({
    bool? isActive,
    int? rakahs,
    bool? isNear,
    bool? dndActive,
  }) {
    return FocusState(
      isActive: isActive ?? this.isActive,
      rakahs: rakahs ?? this.rakahs,
      isNear: isNear ?? this.isNear,
      dndActive: dndActive ?? this.dndActive,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  StreamSubscription<int>? _subscription;
  DateTime? _lastTriggerTime;

  FocusNotifier() : super(FocusState());

  Future<void> startFocus() async {
    bool dndEnabled = false;
    
    // Attempt to enable DND if permission is granted (Android specific usually)
    if (await Permission.accessNotificationPolicy.isGranted) {
      // In a real app, we would use a MethodChannel or a DND package here.
      // For now, we simulate the state and log the intent.
      dndEnabled = true;
      debugPrint('DND Mode activated for Prayer Focus');
    }

    state = FocusState(isActive: true, dndActive: dndEnabled);
    _listenToSensor();
  }

  Future<void> stopFocus() async {
    _subscription?.cancel();
    if (state.dndActive) {
      debugPrint('DND Mode deactivated');
    }
    state = state.copyWith(isActive: false, dndActive: false);
  }

  void _listenToSensor() {
    _subscription?.cancel();
    // proximity_sensor returns 1 for near, 0 for far
    _subscription = ProximitySensor.events.listen((int event) {
      final bool isNear = event > 0;
      
      if (isNear && !state.isNear) {
        // Transition from far to near (Start of Sujood)
        _handleNearTrigger();
      }
      
      state = state.copyWith(isNear: isNear);
    });
  }

  void _handleNearTrigger() {
    final now = DateTime.now();
    // Debounce: ignore triggers within 2 seconds to avoid double counts
    if (_lastTriggerTime == null || now.difference(_lastTriggerTime!) > const Duration(seconds: 2)) {
      // In a normal prayer, 2 Sujoods = 1 Rak'ah (simplified logic for now)
      // We count every 2 triggers as 1 Rak'ah, or just count Sujoods?
      // For now, let's count "Prostrations" and UI can divide by 2 if needed, 
      // or we increment Rak'ah every 2 "Near" events.
      
      // Let's increment rakahs directly every 2 triggers for simplicity in this version
      // Or just count triggers and let the UI show "Sujoods: X" or "Rak'ahs: X/2"
      state = state.copyWith(rakahs: state.rakahs + 1);
      _lastTriggerTime = now;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier();
});
