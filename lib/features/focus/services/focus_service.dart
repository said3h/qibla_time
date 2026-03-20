// lib/features/focus/services/focus_service.dart
//
// Gestiona el estado del modo enfoque:
// - Activación / desactivación
// - Conteo de rak'ahs via sujud (2 sujudes = 1 rak'ah)
// - DND automático
// - Sensor de proximidad

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier();
});

// ── Estado ─────────────────────────────────────────────────────

class FocusState {
  final bool isActive;
  final int  rakahs;
  final bool isNear;       // sensor detecta proximidad ahora mismo
  final bool dndActive;
  final int  sujudCount;   // 0 o 1 — dentro de la rak'ah actual

  const FocusState({
    this.isActive   = false,
    this.rakahs     = 0,
    this.isNear     = false,
    this.dndActive  = false,
    this.sujudCount = 0,
  });

  FocusState copyWith({
    bool? isActive,
    int?  rakahs,
    bool? isNear,
    bool? dndActive,
    int?  sujudCount,
  }) => FocusState(
    isActive:   isActive   ?? this.isActive,
    rakahs:     rakahs     ?? this.rakahs,
    isNear:     isNear     ?? this.isNear,
    dndActive:  dndActive  ?? this.dndActive,
    sujudCount: sujudCount ?? this.sujudCount,
  );
}

// ── Notifier ───────────────────────────────────────────────────

class FocusNotifier extends StateNotifier<FocusState> {
  FocusNotifier() : super(const FocusState());

  StreamSubscription? _sensorSub;

  // Debounce: evita doble conteo si el sensor oscila
  DateTime? _lastSujudTime;
  static const _debounce = Duration(milliseconds: 800);

  // Tiempo mínimo que el sensor debe detectar proximidad
  // para contar como sujud real (evita falsos positivos)
  Timer? _proximityTimer;
  static const _minProximityDuration = Duration(milliseconds: 500);

  // ── Activar ─────────────────────────────────────────────────

  Future<void> activate() async {
    state = const FocusState(isActive: true);
    await _tryEnableDnd();
    _startSensor();
  }

  // ── Desactivar ───────────────────────────────────────────────

  Future<void> deactivate() async {
    _stopSensor();
    await _tryDisableDnd();
    state = const FocusState(isActive: false);
  }

  // ── Sensor de proximidad ─────────────────────────────────────

  void _startSensor() {
    _sensorSub = ProximitySensor.events.listen((int event) {
      final isNear = event > 0;

      if (isNear) {
        // Iniciar timer: solo contar si permanece cerca >= 500ms
        _proximityTimer ??= Timer(_minProximityDuration, () {
          state = state.copyWith(isNear: true);
          _onProximityConfirmed();
        });
      } else {
        // Se alejó
        _proximityTimer?.cancel();
        _proximityTimer = null;
        state = state.copyWith(isNear: false);
      }
    });
  }

  void _stopSensor() {
    _sensorSub?.cancel();
    _sensorSub = null;
    _proximityTimer?.cancel();
    _proximityTimer = null;
  }

  void _onProximityConfirmed() {
    final now = DateTime.now();

    // Debounce: ignorar si el último sujud fue hace menos de 800ms
    if (_lastSujudTime != null &&
        now.difference(_lastSujudTime!) < _debounce) return;

    _lastSujudTime = now;

    final newSujudCount = state.sujudCount + 1;

    if (newSujudCount >= 2) {
      // Segundo sujud → completar rak'ah
      HapticFeedback.mediumImpact();
      state = state.copyWith(
        rakahs:     state.rakahs + 1,
        sujudCount: 0,
      );
    } else {
      // Primer sujud
      HapticFeedback.lightImpact();
      state = state.copyWith(sujudCount: newSujudCount);
    }
  }

  // ── Incremento manual (fallback) ─────────────────────────────

  void incrementRakahs() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(rakahs: state.rakahs + 1);
  }

  // ── DND ──────────────────────────────────────────────────────

  static const _dndChannel = MethodChannel('com.qiblatime/dnd');

  Future<void> _tryEnableDnd() async {
    try {
      final granted = await _dndChannel.invokeMethod<bool>('enableDnd');
      state = state.copyWith(dndActive: granted ?? false);
    } on PlatformException {
      state = state.copyWith(dndActive: false);
    }
  }

  Future<void> _tryDisableDnd() async {
    try {
      await _dndChannel.invokeMethod('disableDnd');
    } on PlatformException {
      // silencioso
    }
  }

  @override
  void dispose() {
    _stopSensor();
    super.dispose();
  }
}
