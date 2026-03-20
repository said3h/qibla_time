// lib/features/tracking/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tracking_service.dart';
import '../models/tracking_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(prayerTrackingProvider);
    final themeName = ref.watch(themeControllerProvider);
    final tokens = QiblaThemes.fromName(themeName);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        elevation: 0,
        title: Text(
          'Estadísticas',
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: tokens.border),
        ),
      ),
      body: RefreshIndicator(
        color: tokens.primary,
        onRefresh: () async => ref.refresh(prayerTrackingProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── 1. RACHA ──────────────────────────────────────
            _StreakCard(tracking: tracking, tokens: tokens),
            const SizedBox(height: 16),

            // ── 2. HEATMAP ────────────────────────────────────
            _HeatmapCard(tracking: tracking, tokens: tokens),
            const SizedBox(height: 16),

            // ── 3. PROGRESO POR ORACIÓN ───────────────────────
            _PrayerProgressCard(tracking: tracking, tokens: tokens),
            const SizedBox(height: 16),

            // ── 4. TOTALES DEL MES ────────────────────────────
            _MonthlyTotalsCard(tracking: tracking, tokens: tokens),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 1. TARJETA DE RACHA
// ══════════════════════════════════════════════════════════════

class _StreakCard extends StatelessWidget {
  final TrackingState tracking;
  final QiblaTokens   tokens;

  const _StreakCard({required this.tracking, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final streak = tracking.currentStreak;
    final best   = tracking.bestStreak;

    return _Card(
      tokens: tokens,
      child: Row(
        children: [
          // Llama de racha
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Center(
              child: Text(
                streak > 0 ? '🔥' : '💤',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Números
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? 'Sin racha activa'
                      : '$streak ${streak == 1 ? 'día' : 'días'} seguidos',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tokens.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 0
                      ? 'Reza hoy las 5 oraciones para empezar'
                      : 'Mejor racha: $best días',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Mejor racha badge
          if (streak == best && best > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Text(
                '⭐ Récord',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.primaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 2. HEATMAP DE 30 DÍAS
// ══════════════════════════════════════════════════════════════

class _HeatmapCard extends StatelessWidget {
  final TrackingState tracking;
  final QiblaTokens   tokens;

  const _HeatmapCard({required this.tracking, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final days = tracking.last30Days;

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Últimos 30 días', tokens: tokens),
          const SizedBox(height: 14),

          // Grid 6 filas × 5 columnas = 30 días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) => _HeatCell(day: days[i], tokens: tokens),
          ),

          const SizedBox(height: 12),

          // Leyenda
          Row(
            children: [
              Text(
                'Menos',
                style: GoogleFonts.dmSans(
                  fontSize: 10, color: tokens.textMuted),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: _legendCell(i, tokens),
              )),
              const SizedBox(width: 6),
              Text(
                'Más',
                style: GoogleFonts.dmSans(
                  fontSize: 10, color: tokens.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendCell(int level, QiblaTokens tokens) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: _heatColor(level, tokens),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Color _heatColor(int level, QiblaTokens tokens) {
    switch (level) {
      case 0: return tokens.bgSurface2;
      case 1: return tokens.primary.withOpacity(0.20);
      case 2: return tokens.primary.withOpacity(0.40);
      case 3: return tokens.primary.withOpacity(0.65);
      default: return tokens.primary;
    }
  }
}

class _HeatCell extends StatelessWidget {
  final HeatmapDay  day;
  final QiblaTokens tokens;

  const _HeatCell({required this.day, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Tooltip(
      message: '${_dayLabel()}: ${day.completed}/5',
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: day.isToday
              ? Border.all(color: tokens.primary, width: 1.5)
              : null,
        ),
      ),
    );
  }

  Color _color() {
    if (day.completed == 0) return tokens.bgSurface2;
    if (day.completed <= 1) return tokens.primary.withOpacity(0.20);
    if (day.completed <= 2) return tokens.primary.withOpacity(0.40);
    if (day.completed <= 4) return tokens.primary.withOpacity(0.65);
    return tokens.primary; // 5/5 = color completo
  }

  String _dayLabel() {
    return '${day.date.day}/${day.date.month}';
  }
}

// ══════════════════════════════════════════════════════════════
// 3. PROGRESO POR ORACIÓN
// ══════════════════════════════════════════════════════════════

class _PrayerProgressCard extends StatelessWidget {
  final TrackingState tracking;
  final QiblaTokens   tokens;

  const _PrayerProgressCard({required this.tracking, required this.tokens});

  static const _prayers = [
    ('fajr',    'Fajr',    'فجر'),
    ('dhuhr',   'Dhuhr',   'ظهر'),
    ('asr',     'Asr',     'عصر'),
    ('maghrib', 'Maghrib', 'مغرب'),
    ('isha',    'Isha',    'عشاء'),
  ];

  @override
  Widget build(BuildContext context) {
    final completion = tracking.prayerCompletion;

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Por oración — últimos 30 días', tokens: tokens),
          const SizedBox(height: 14),
          ..._prayers.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PrayerBar(
              name:       p.$2,
              arabic:     p.$3,
              ratio:      completion[p.$1] ?? 0.0,
              tokens:     tokens,
            ),
          )),
        ],
      ),
    );
  }
}

class _PrayerBar extends StatelessWidget {
  final String      name;
  final String      arabic;
  final double      ratio;    // 0.0 - 1.0
  final QiblaTokens tokens;

  const _PrayerBar({
    required this.name,
    required this.arabic,
    required this.ratio,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();

    return Column(
      children: [
        Row(
          children: [
            // Nombre
            SizedBox(
              width: 64,
              child: Text(
                name,
                style: GoogleFonts.amiri(
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            // Árabe
            Text(
              arabic,
              style: GoogleFonts.amiri(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const Spacer(),
            // Porcentaje
            Text(
              '$pct%',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _barColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: tokens.bgSurface2,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
          ),
        ),
      ],
    );
  }

  Color _barColor() {
    if (ratio >= 0.8) return tokens.primary;
    if (ratio >= 0.5) return tokens.primary.withOpacity(0.7);
    return tokens.primary.withOpacity(0.4);
  }
}

// ══════════════════════════════════════════════════════════════
// 4. TOTALES DEL MES
// ══════════════════════════════════════════════════════════════

class _MonthlyTotalsCard extends StatelessWidget {
  final TrackingState tracking;
  final QiblaTokens   tokens;

  const _MonthlyTotalsCard({required this.tracking, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final stats = tracking.currentMonthStats;
    final pct   = (stats.completionRate * 100).round();

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: stats.monthName, tokens: tokens),
          const SizedBox(height: 16),

          Row(
            children: [
              // Círculo de progreso
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: stats.completionRate,
                      strokeWidth: 7,
                      backgroundColor: tokens.bgSurface2,
                      valueColor: AlwaysStoppedAnimation(tokens.primary),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: tokens.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Stats en columna
              Expanded(
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Oraciones completadas',
                      value: '${stats.prayersCompleted} / ${stats.maxPossible}',
                      tokens: tokens,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      label: 'Días completos (5/5)',
                      value: '${stats.fullDays} días',
                      tokens: tokens,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      label: 'Mejor racha',
                      value: '${tracking.bestStreak} días',
                      tokens: tokens,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String      label;
  final String      value;
  final QiblaTokens tokens;

  const _StatRow({
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS DE APOYO
// ══════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget      child;
  final QiblaTokens tokens;

  const _Card({required this.child, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String      title;
  final QiblaTokens tokens;

  const _SectionTitle({required this.title, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
        letterSpacing: 1.4,
      ),
    );
  }
}
