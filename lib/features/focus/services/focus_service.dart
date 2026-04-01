import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  
  // Debug flag - set to true for verbose logging
  static const _debugMode = true;

  void _log(String msg) {
    if (_debugMode) {
      debugPrint('[FOCUS] $msg');
    }
  }

  Future<void> activate() async {
    _log('=== ACTIVATE called ===');
    _resetSensorSession();
    state = const FocusState(isActive: true, sensorAvailable: true);
    await _tryEnableDnd();
    _startSensor();
    _log('=== ACTIVATE complete ===');
  }

  Future<void> deactivate() async {
    _log('=== DEACTIVATE called ===');
    _resetSensorSession();
    await _tryDisableDnd();
    state = const FocusState(isActive: false);
  }

  void _startSensor() {
    _log('_startSensor: Starting sensor subscription');
    _stopSensor();
    _sensorSub = _proximityEvents().listen(
      (dynamic event) {
        if (!state.isActive) {
          _log('_startSensor: IGNORED event - state not active');
          return;
        }

        final isNear = event is int ? event > 0 : event == true;
        _log('_startSensor: event=$event, isNear=$isNear, wasNear=${state.isNear}');
        
        if (isNear && !state.isNear) {
          _log('_startSensor: PROXIMITY CONFIRMED - calling _onProximityConfirmed()');
          _onProximityConfirmed();
        }

        state = state.copyWith(
          isNear: isNear,
          sensorAvailable: true,
        );
      },
      onError: (error, stackTrace) {
        _log('_startSensor: ERROR - error=$error, stackTrace=$stackTrace');
        _stopSensor();
        if (!state.isActive) return;
        state = state.copyWith(
          isNear: false,
          sensorAvailable: false,
        );
      },
      onDone: () {
        _log('_startSensor: Stream DONE');
      },
    );
    _log('_startSensor: Sensor subscription established');
  }

  Stream<int> _proximityEvents() {
    if (kIsWeb) {
      _log('_proximityEvents: Web platform - returning empty stream');
      return const Stream<int>.empty();
    }

    _log('_proximityEvents: Setting up receiveBroadcastStream');
    return _proximityEventChannel.receiveBroadcastStream().map((dynamic event) {
      _log('_proximityEvents: Received raw event=$event (type: ${event.runtimeType})');
      if (event is int) {
        _log('_proximityEvents: Mapped int event=$event');
        return event;
      }
      if (event is bool) {
        final val = event ? 1 : 0;
        _log('_proximityEvents: Mapped bool event=$event -> $val');
        return val;
      }
      throw StateError('Unexpected proximity event type: ${event.runtimeType}');
    });
  }

  void _onProximityConfirmed() {
    _log('_onProximityConfirmed: ENTER');
    final now = DateTime.now();
    if (_lastSujudTime != null &&
        now.difference(_lastSujudTime!) < _debounce) {
      _log('_onProximityConfirmed: DEBOUNCED - too soon');
      return;
    }

    _lastSujudTime = now;
    final newSujudCount = state.sujudCount + 1;
    _log('_onProximityConfirmed: newSujudCount=$newSujudCount, currentRakahs=${state.rakahs}');

    if (newSujudCount >= 2) {
      HapticFeedback.mediumImpact();
      _log('_onProximityConfirmed: RAKAH COMPLETED - incrementing rakahs');
      state = state.copyWith(
        rakahs: state.rakahs + 1,
        sujudCount: 0,
      );
      return;
    }

    HapticFeedback.lightImpact();
    _log('_onProximityConfirmed: SUDJUD #$newSujudCount registered');
    state = state.copyWith(sujudCount: newSujudCount);
  }

  void incrementRakahs() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(rakahs: state.rakahs + 1);
  }

  Future<void> _tryEnableDnd() async {
    try {
      _log('_tryEnableDnd: Calling platform method');
      final granted = await _dndChannel.invokeMethod<bool>('enableDnd');
      state = state.copyWith(dndActive: granted ?? false);
      _log('_tryEnableDnd: granted=$granted');
    } on PlatformException catch (e) {
      _log('_tryEnableDnd: PlatformException - code=${e.code}, message=${e.message}');
      state = state.copyWith(dndActive: false);
    }
  }

  Future<void> _tryDisableDnd() async {
    try {
      await _dndChannel.invokeMethod('disableDnd');
      _log('_tryDisableDnd: Success');
    } on PlatformException catch (e) {
      _log('_tryDisableDnd: PlatformException - code=${e.code}, message=${e.message}');
      // Keep focus mode usable even when the platform call is unavailable.
    }
  }

  void _resetSensorSession() {
    _log('_resetSensorSession: Resetting');
    _stopSensor();
    _lastSujudTime = null;
  }

  void _stopSensor() {
    _log('_stopSensor: Cancelling subscription');
    _sensorSub?.cancel();
    _sensorSub = null;
  }

  @override
  void dispose() {
    _log('dispose: Cleaning up');
    _resetSensorSession();
    super.dispose();
  }
}
