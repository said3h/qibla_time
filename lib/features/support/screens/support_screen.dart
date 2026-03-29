import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Apoya Qibla Time',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.favorite_rounded, color: tokens.primary, size: 72),
          const SizedBox(height: 20),
          Text(
            'Jazak Allahu khayran',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Qibla Time es gratuita y sin anuncios intrusivos. Esta pantalla resume formas reales y honestas de apoyar el proyecto, sin prometer acciones que todavía no existen dentro de la app.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 28),
          _SupportInfoCard(
            icon: Icons.star_rate_rounded,
            title: 'Valora la app',
            description:
                'Cuando la ficha definitiva de tienda esté disponible, una reseña ayudará a que más personas encuentren Qibla Time.',
          ),
          _SupportInfoCard(
            icon: Icons.share_rounded,
            title: 'Compártela con otras personas',
            description:
                'Recomendar Qibla Time a familiares y amistades también es una forma real de apoyar el proyecto.',
          ),
          _SupportInfoCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'Sadaqah',
            description:
                'La opción de apoyo económico todavía no está habilitada dentro de la app.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              '"La caridad no disminuye la riqueza."',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportInfoCard extends StatelessWidget {
  const _SupportInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Icon(icon, color: tokens.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
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
