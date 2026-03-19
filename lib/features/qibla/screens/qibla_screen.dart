import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/qibla_service.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla de Qibla con brújula mejorada
/// Diseño inspirado en prototipo: Kaaba en el borde del círculo
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compassAsync = ref.watch(compassProvider);
    final bearingAsync = ref.watch(qiblaBearingProvider);
    final distanceAsync = ref.watch(distanceToMeccaProvider);

    return Scaffold(
      backgroundColor: AppTheme.night,
      appBar: AppBar(
        title: Text(
          'Qibla',
          style: GoogleFonts.amiri(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.gold),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Información de distancia
                    distanceAsync.when(
                      data: (dist) => dist != null
                          ? _buildDistanceCard(dist)
                          : const SizedBox(),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Brújula principal con Kaaba en el borde
                    _buildCompassVisuals(compassRotation, qiblaRotation),
                    
                    const SizedBox(height: 32),
                    
                    // Información de dirección
                    _buildDirectionInfo(heading, qiblaBearing),
                    
                    const SizedBox(height: 24),
                    
                    // Método de cálculo
                    _buildCalculationMethodCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Tips de precisión
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Mantén el dispositivo plano y alejado de imanes para mayor precisión.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: AppTheme.gold)),
            error: (error, _) => _buildSensorError('Location Service Error: $error'),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.gold),
              const SizedBox(height: 16),
              Text(
                'Inicializando brújula...',
                style: GoogleFonts.dmSans(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        error: (error, _) => _buildSensorError('Compass Sensor Error: $error'),
      ),
    );
  }

  Widget _buildDistanceCard(double distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.15),
            AppTheme.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.place_outlined,
            value: distance.toStringAsFixed(0),
            unit: 'km',
            label: 'Distancia a la Kaaba',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.gold.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Icons.my_location,
            value: '±3',
            unit: 'm',
            label: 'Precisión GPS',
            valueColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.gold, size: 24),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.goldLight,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: unit,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildCompassVisuals(double compassRotation, double qiblaRotation) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.surface,
            AppTheme.surface.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo decorativo exterior
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold.withOpacity(0.1), width: 1),
            ),
          ),
          
          // Anillo con marcas de grados
          Transform.rotate(
            angle: compassRotation,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Norte (rojo)
                  const Positioned(
                    top: 0,
                    child: Text('N', style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    )),
                  ),
                  // Sur
                  Positioned(
                    bottom: 0,
                    child: Text('S', style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.muted,
                    )),
                  ),
                  // Este
                  Positioned(
                    right: 0,
                    child: Text('E', style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.muted,
                    )),
                  ),
                  // Oeste
                  Positioned(
                    left: 0,
                    child: Text('O', style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.muted,
                    )),
                  ),
                ],
              ),
            ),
          ),
          
          // Líneas de grados decorativas
          ...List.generate(36, (index) {
            final angle = (index * 10) * (pi / 180);
            final isMajor = index % 9 == 0;
            return Transform.rotate(
              angle: angle + compassRotation,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: isMajor ? 2 : 1,
                  height: isMajor ? 15 : 8,
                  margin: const EdgeInsets.only(top: 8),
                  color: isMajor 
                      ? AppTheme.gold.withOpacity(0.5) 
                      : AppTheme.gold.withOpacity(0.2),
                ),
              ),
            );
          }),
          
          // Aguja de Qibla (apunta hacia la Kaaba)
          Transform.rotate(
            angle: compassRotation + qiblaRotation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kaaba en el BORDE del círculo (como en el prototipo)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mosque,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                // Línea conectora (aguja)
                Container(
                  width: 4,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.gold,
                        AppTheme.gold.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          
          // Centro de la brújula
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionInfo(double heading, double qiblaBearing) {
    final direction = _getDirectionName(qiblaBearing);
    
    return Column(
      children: [
        Text(
          '${qiblaBearing.toStringAsFixed(0)}°',
          style: GoogleFonts.amiri(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: AppTheme.goldLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, size: 16, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text(
                '$direction • Sureste',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDirectionName(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Noreste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Este';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sureste';
    if (bearing >= 157.5 && bearing < 202.5) return 'Sur';
    if (bearing >= 202.5 && bearing < 247.5) return 'Suroeste';
    if (bearing >= 247.5 && bearing < 292.5) return 'Oeste';
    if (bearing >= 292.5 && bearing < 337.5) return 'Noroeste';
    return 'Norte';
  }

  Widget _buildCalculationMethodCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MÉTODO DE CÁLCULO',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMethodChip('MWL', true),
              _buildMethodChip('ISNA', false),
              _buildMethodChip('Egypt', false),
              _buildMethodChip('Makkah', false),
              _buildMethodChip('Tehran', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.gold.withOpacity(0.15) 
            : AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? AppTheme.gold.withOpacity(0.3) 
              : AppTheme.border,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? AppTheme.goldLight : AppTheme.muted,
        ),
      ),
    );
  }

  Widget _buildSensorError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_outlined, size: 80, color: Colors.redAccent.withOpacity(0.7)),
            const SizedBox(height: 24),
            Text(
              'Sensor Issue',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppTheme.muted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRequiredError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 80, color: AppTheme.muted),
            const SizedBox(height: 24),
            Text(
              'Acceso a Ubicación Requerido',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Permite el acceso a la ubicación para calcular la dirección precisa de la Qibla.',
              style: GoogleFonts.dmSans(
                color: AppTheme.muted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openLocationSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Configuración'),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationSettings() {
    // Implementar apertura de configuración
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cómo usar la brújula',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              Icons.phone_android,
              'Mantén el dispositivo plano',
              'Evita inclinaciones para mayor precisión',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.block,
              'Aleja de imanes',
              'Los campos magnéticos afectan la brújula',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.refresh,
              'Calibra si es necesario',
              'Mueve en forma de 8 si la precisión es baja',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.gold, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

