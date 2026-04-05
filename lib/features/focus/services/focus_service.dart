import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibla_time/core/services/logger_service.dart';

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier();
});

class FocusState {
  final bool isActive;
  final int rakahs;
  final bool isNear;
  final bool dndActive;
  final int sujudCount;
  final bool sensorAvailable;

  const FocusState({
    this.isActive = false,
    this.rakahs = 0,
    this.isNear = false,
    this.dndActive = false,
    this.sujudCount = 0,
    this.sensorAvailable = true,
  });

  FocusState copyWith({
    bool? isActive,
    int? rakahs,
    bool? isNear,
    bool? dndActive,
    int? sujudCount,
    bool? sensorAvailable,
  }) {
    return FocusState(
      isActive: isActive ?? this.isActive,
      rakahs: rakahs ?? this.rakahs,
      isNear: isNear ?? this.isNear,
      dndActive: dndActive ?? this.dndActive,
      sujudCount: sujudCount ?? this.sujudCount,
      sensorAvailable: sensorAvailable ?? this.sensorAvailable,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  FocusNotifier() : super(const FocusState());

  static const _proximityEventChannel = EventChannel('com.qiblatime/proximity');
  StreamSubscription<dynamic>? _sensorSub;
  DateTime? _lastSujudTime;

  static const _debounce = Duration(milliseconds: 800);
  static const _dndChannel = MethodChannel('com.qiblatime/dnd');

  Future<void> activate() async {
    _resetSensorSession();
    state = const FocusState(isActive: true, sensorAvailable: true);
    await _tryEnableDnd();
    if (!state.isActive) {
      return;
    }
    _startSensor();
  }

  Future<void> deactivate() async {
    _resetSensorSession();
    state = const FocusState(isActive: false);
    await _tryDisableDnd();
  }

  void _startSensor() {
    _stopSensor();
    try {
      _sensorSub = _proximityEvents().listen(
        (dynamic event) {
          if (!state.isActive) return;

          final isNear = event is int ? event > 0 : event == true;
          if (isNear && !state.isNear) {
            _onProximityConfirmed();
          }

          state = state.copyWith(
            isNear: isNear,
            sensorAvailable: true,
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.error(
            'Failed while listening to proximity sensor',
            error: error,
            stackTrace: stackTrace,
          );
          _stopSensor();
          if (!state.isActive) return;
          state = state.copyWith(
            isNear: false,
            sensorAvailable: false,
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start proximity sensor',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isNear: false,
        sensorAvailable: false,
      );
    }
  }

  Stream<int> _proximityEvents() {
    return _proximityEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is int) {
        return event;
      }
      if (event is bool) {
        return event ? 1 : 0;
      }
      throw StateError('Unexpected proximity event type: ${event.runtimeType}');
    });
  }

  void _onProximityConfirmed() {
    final now = DateTime.now();
    if (_lastSujudTime != null &&
        now.difference(_lastSujudTime!) < _debounce) {
      return;
    }

    _lastSujudTime = now;
    final newSujudCount = state.sujudCount + 1;

    if (newSujudCount >= 2) {
      HapticFeedback.mediumImpact();
      state = state.copyWith(
        rakahs: state.rakahs + 1,
        sujudCount: 0,
      );
      return;
    }

    HapticFeedback.lightImpact();
    state = state.copyWith(sujudCount: newSujudCount);
  }

  void incrementRakahs() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(rakahs: state.rakahs + 1);
  }

  Future<void> _tryEnableDnd() async {
    try {
      final granted = await _dndChannel.invokeMethod<bool>('enableDnd');
      state = state.copyWith(dndActive: granted ?? false);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to enable Do Not Disturb for focus mode',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(dndActive: false);
    }
  }

  Future<void> _tryDisableDnd() async {
    try {
      await _dndChannel.invokeMethod('disableDnd');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to disable Do Not Disturb for focus mode',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _resetSensorSession() {
    _stopSensor();
    _lastSujudTime = null;
  }

  void _stopSensor() {
    _sensorSub?.cancel();
    _sensorSub = null;
  }

  @override
  void dispose() {
    _resetSensorSession();
    if (state.isActive || state.dndActive) {
      unawaited(_tryDisableDnd());
    }
    super.dispose();
  }
}
