import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MosqueState {
  final bool isInsideMosque;
  final String? mosqueName;
  final double distance;

  MosqueState({
    this.isInsideMosque = false,
    this.mosqueName,
    this.distance = double.infinity,
  });

  MosqueState copyWith({
    bool? isInsideMosque,
    String? mosqueName,
    double? distance,
  }) {
    return MosqueState(
      isInsideMosque: isInsideMosque ?? this.isInsideMosque,
      mosqueName: mosqueName ?? this.mosqueName,
      distance: distance ?? this.distance,
    );
  }
}

class MosqueNotifier extends StateNotifier<MosqueState> {
  StreamSubscription<Position>? _positionSubscription;
  
  // Example "Home Masjid" coordinates (to be configurable by user later)
  static const double _targetLat = 40.4168; // Madrid example
  static const double _targetLon = -3.7038;
  static const double _geofenceRadius = 50.0; // 50 meters

  MosqueNotifier() : super(MosqueState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _checkProximity(position);
    });
  }

  void _checkProximity(Position position) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _targetLat,
      _targetLon,
    );

    final bool isInside = distance <= _geofenceRadius;
    
    if (isInside && !state.isInsideMosque) {
      debugPrint('Entered Mosque Mode: Auto-silencing...');
      // Logic to silence notifications would go here or be triggered by listeners
    } else if (!isInside && state.isInsideMosque) {
      debugPrint('Exited Mosque Mode: Restoring settings...');
    }

    state = MosqueState(
      isInsideMosque: isInside,
      mosqueName: isInside ? "Mezquita Central" : null,
      distance: distance,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final mosqueProvider = StateNotifierProvider<MosqueNotifier, MosqueState>((ref) {
  return MosqueNotifier();
});
