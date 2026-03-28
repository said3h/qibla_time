import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../prayer_times/domain/entities/prayer_location_diagnostic.dart';
import '../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../services/qibla_service.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final compassAsync = ref.watch(compassProvider);
    final bearingAsync = ref.watch(qiblaBearingProvider);
    final distanceAsync = ref.watch(distanceToMeccaProvider);
    final locationDiagnosticAsync = ref.watch(prayerLocationDiagnosticProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: compassAsync.when(
          data: (CompassEvent event) {
            final heading = event.heading;
            if (heading == null) {
              return _buildError(
                tokens,
                'No pudimos leer la brújula. Prueba a mover el teléfono en forma de 8 y aléjalo de fundas magnéticas.',
              );
            }

            return bearingAsync.when(
              data: (bearing) {
                if (bearing == null) {
                  return _buildLocationIssue(
                    tokens,
                    locationDiagnosticAsync.valueOrNull,
                  );
                }

                final dialRotation = -(heading * pi / 180);
                final needleRotation = (bearing - heading) * pi / 180;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    children: [
                      _buildHeader(context, tokens),
                      const SizedBox(height: 18),
                      distanceAsync.when(
                        data: (distance) => _buildDistanceCard(tokens, distance),
                        loading: () => _buildDistanceCard(tokens, null),
                        error: (_, __) => _buildDistanceCard(tokens, null),
                      ),
                      const SizedBox(height: 20),
                      _buildCompass(tokens, dialRotation, needleRotation),
                      const SizedBox(height: 18),
                      Text(
                        '${bearing.toStringAsFixed(0)}°',
                        style: GoogleFonts.amiri(
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          color: tokens.primaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: tokens.bgSurface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Text(
                          'Qibla · ${_getDirectionName(bearing)} · Dirección a la Kaaba',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Mantén el dispositivo plano y alejado de imanes para mayor precisión.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            height: 1.6,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildLoading(tokens),
              error: (_, __) => _buildError(
                tokens,
                'No se pudo calcular la dirección a la Kaaba con esta ubicación.',
              ),
            );
          },
          loading: () => _buildLoading(tokens),
          error: (_, __) => _buildError(
            tokens,
            'No se pudo iniciar la brújula. Comprueba si tu dispositivo dispone de sensor magnético.',
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QiblaTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qibla',
                style: GoogleFonts.amiri(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
              Text(
                'القبلة · Dirección a la Kaaba',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showInfoDialog(context, tokens),
          icon: Icon(Icons.info_outline, color: tokens.primary),
        ),
      ],
    );
  }

  Widget _buildDistanceCard(QiblaTokens tokens, double? distance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(tokens, Icons.place_outlined, distance == null ? '--' : distance.toStringAsFixed(0), 'km', 'Distancia'),
          Container(width: 1, height: 40, color: tokens.primaryBorder),
          _buildStat(tokens, Icons.my_location, '±3', 'm', 'Precisión', valueColor: tokens.accent),
        ],
      ),
    );
  }

  Widget _buildStat(
    QiblaTokens tokens,
    IconData icon,
    String value,
    String unit,
    String label, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: tokens.primary),
        const SizedBox(height: 5),
        RichText(
          text: TextSpan(
            text: value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: valueColor ?? tokens.primaryLight,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCompass(QiblaTokens tokens, double dialRotation, double needleRotation) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.bgSurface,
        border: Border.all(color: tokens.primaryBorder, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.border),
            ),
          ),
          Transform.rotate(
            angle: dialRotation,
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(36, (index) {
                    final isMajor = index % 9 == 0;
                    return Transform.rotate(
                      angle: index * 10 * pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: isMajor ? 2 : 1,
                          height: isMajor ? 14 : 9,
                          margin: const EdgeInsets.only(top: 10),
                          color: tokens.primary.withOpacity(isMajor ? 0.55 : 0.22),
                        ),
                      ),
                    );
                  }),
                  Positioned(top: 24, child: _cardinal('N', Colors.red.shade400)),
                  Positioned(bottom: 24, child: _cardinal('S', tokens.textSecondary)),
                  Positioned(right: 24, child: _cardinal('E', tokens.textSecondary)),
                  Positioned(left: 24, child: _cardinal('O', tokens.textSecondary)),
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: needleRotation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.primary,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(child: Text('🕋', style: TextStyle(fontSize: 20))),
                ),
                Container(
                  width: 3,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tokens.primary, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.primary,
              border: Border.all(color: tokens.bgApp, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardinal(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildLoading(QiblaTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: tokens.primary),
          const SizedBox(height: 14),
          Text(
            'Inicializando brújula...',
            style: GoogleFonts.dmSans(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(QiblaTokens tokens, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tokens.bgSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.border),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: tokens.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIssue(
    QiblaTokens tokens,
    PrayerLocationDiagnostic? diagnostic,
  ) {
    String text = 'Activa la ubicación para calcular la dirección de la Qibla.';
    if (diagnostic != null) {
      if (!diagnostic.serviceEnabled) {
        text =
            'La ubicación del dispositivo está desactivada. Activa el GPS para calcular la Qibla con precisión.';
      } else if (diagnostic.permissionStatus ==
          PrayerLocationPermissionStatus.deniedForever) {
        text =
            'El permiso de ubicación está bloqueado. Puedes activarlo desde los ajustes del sistema.';
      } else if (diagnostic.permissionStatus ==
          PrayerLocationPermissionStatus.denied) {
        text =
            'La app necesita permiso de ubicación para orientar la Qibla correctamente.';
      }
    }
    return _buildError(tokens, text);
  }

  String _getDirectionName(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'Norte';
    if (bearing < 67.5) return 'Noreste';
    if (bearing < 112.5) return 'Este';
    if (bearing < 157.5) return 'Sureste';
    if (bearing < 202.5) return 'Sur';
    if (bearing < 247.5) return 'Suroeste';
    if (bearing < 292.5) return 'Oeste';
    return 'Noroeste';
  }

  void _showInfoDialog(BuildContext context, QiblaTokens tokens) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: tokens.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cómo usar la brújula',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    color: tokens.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(tokens, '📱', 'Mantén el dispositivo plano', 'Evita inclinaciones para ganar precisión'),
                _infoRow(tokens, '🚫', 'Aleja imanes y metal', 'Los campos magnéticos afectan a la lectura'),
                _infoRow(tokens, '🔄', 'Calibra si es necesario', 'Mueve el teléfono en forma de 8'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(QiblaTokens tokens, String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
