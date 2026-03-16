import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/qibla_service.dart';
import '../../../core/theme/app_theme.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compassAsync = ref.watch(compassProvider);
    final bearingAsync = ref.watch(qiblaBearingProvider);
    final distanceAsync = ref.watch(distanceToMeccaProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Qibla Compass', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: compassAsync.when(
        data: (CompassEvent event) {
          final heading = event.heading;
          if (heading == null) {
            return _buildSensorError('Compass heading is null. Try moving the device in a figure-eight pattern.');
          }

          return bearingAsync.when(
            data: (double? qiblaBearing) {
              if (qiblaBearing == null) {
                return _buildLocationRequiredError();
              }

              final compassRotation = -1 * (heading * (pi / 180));
              final qiblaRotation = qiblaBearing * (pi / 180);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   distanceAsync.when(
                    data: (dist) => dist != null 
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Text(
                              'Distance to Kaaba: ${dist.toStringAsFixed(0)} km',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          )
                        : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  _buildCompassVisuals(compassRotation, qiblaRotation),
                  const SizedBox(height: 40),
                  Text(
                    'Heading: ${heading.toInt()}°',
                    style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Keep your device flat and away from magnets for best accuracy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                    ),
                  )
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (error, _) => _buildSensorError('Location Service Error: $error'),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 16),
              Text('Initializing Compass...'),
            ],
          ),
        ),
        error: (error, _) => _buildSensorError('Compass Sensor Error: $error'),
      ),
    );
  }

  Widget _buildSensorError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off_outlined, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Sensor Issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassVisuals(double compassRotation, double qiblaRotation) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Compass dial rotating based on heading
          Transform.rotate(
            angle: compassRotation,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    spreadRadius: 10,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('N', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.red)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryGreen)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Qibla Pointer
          Transform.rotate(
            angle: compassRotation + qiblaRotation,
            child: const Icon(
              Icons.navigation,
              size: 100,
              color: AppTheme.accentGold,
            ),
          ),
          // Kaaba Center Icon
          Container(
             width: 40,
             height: 40,
             decoration: const BoxDecoration(
               color: AppTheme.primaryGreen,
               shape: BoxShape.circle,
             ),
             child: const Center(
               child: Icon(Icons.mosque, color: Colors.white, size: 24)
             ),
          )
        ],
      ),
    );
  }

  Widget _buildLocationRequiredError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'Location Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please grant location permissions to determine the accurate Qibla direction from your current area.',
              style: TextStyle(color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
