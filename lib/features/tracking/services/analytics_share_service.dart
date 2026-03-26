import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tracking_models.dart';

final analyticsShareServiceProvider = Provider<AnalyticsShareService>((ref) {
  return AnalyticsShareService();
});

class AnalyticsShareService {
  Future<void> shareWeeklyProgressAsImage(
    TrackingState tracking,
    QiblaTokens tokens,
  ) async {
    final summary = tracking.currentWeekSummary;
    final bytes = await _renderCard(summary, tracking, tokens);
    final directory =
        await Directory.systemTemp.createTemp('qiblatime_analytics');
    final file = File('${directory.path}/weekly_progress.png');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: _shareText(summary, tracking),
    );
  }

  Future<void> shareWeeklyProgressAsText(TrackingState tracking) {
    final summary = tracking.currentWeekSummary;
    return Share.share(_shareText(summary, tracking));
  }

  String _shareText(WeeklySummary summary, TrackingState tracking) {
    return 'Mi progreso en QiblaTime\n'
        'Racha actual: ${tracking.currentStreak} dias\n'
        'Esta semana: ${summary.prayersCompleted}/${summary.maxPossible} oraciones\n'
        'Mejor dia: ${summary.strongestDay.shortLabel}\n'
        '${summary.interpretation}';
  }

  Future<Uint8List> _renderCard(
    WeeklySummary summary,
    TrackingState tracking,
    QiblaTokens tokens,
  ) async {
    const width = 1080.0;
    const height = 1350.0;
    const horizontalPadding = 92.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = const Rect.fromLTWH(0, 0, width, height);

    final background = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(width, height),
        [tokens.bgPage, tokens.primaryBg],
      );
    canvas.drawRect(bounds, background);

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 72, width - 144, height - 144),
      const Radius.circular(44),
    );
    canvas.drawRRect(cardRect, Paint()..color = tokens.bgSurface);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = tokens.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _paintText(
      canvas,
      text: 'TU SEMANA',
      style: GoogleFonts.dmSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: tokens.primary,
      ),
      offset: const Offset(horizontalPadding, 126),
      maxWidth: 320,
    );

    _paintText(
      canvas,
      text: '${tracking.currentStreak}',
      style: GoogleFonts.dmSans(
        fontSize: 148,
        fontWeight: FontWeight.w700,
        color: tokens.primaryLight,
      ),
      offset: const Offset(horizontalPadding, 194),
      maxWidth: 340,
    );

    _paintText(
      canvas,
      text: tracking.currentStreak == 1 ? 'dia seguido' : 'dias seguidos',
      style: GoogleFonts.dmSans(
        fontSize: 28,
        color: tokens.textSecondary,
      ),
      offset: const Offset(horizontalPadding, 354),
      maxWidth: 300,
    );

    final statsTop = 470.0;
    _drawStatCard(
      canvas,
      tokens: tokens,
      rect: const Rect.fromLTWH(92, statsTop, 280, 172),
      value: '${summary.prayersCompleted}/${summary.maxPossible}',
      label: 'oraciones esta semana',
    );
    _drawStatCard(
      canvas,
      tokens: tokens,
      rect: const Rect.fromLTWH(400, statsTop, 280, 172),
      value: summary.strongestDay.shortLabel,
      label: '${summary.strongestDay.completed}/5 mejor dia',
    );
    _drawStatCard(
      canvas,
      tokens: tokens,
      rect: const Rect.fromLTWH(708, statsTop, 280, 172),
      value: '${summary.fullDays}',
      label: 'dias completos',
    );

    _paintText(
      canvas,
      text: summary.interpretation,
      style: GoogleFonts.dmSans(
        fontSize: 32,
        height: 1.5,
        color: tokens.textPrimary,
      ),
      offset: const Offset(horizontalPadding, 720),
      maxWidth: width - (horizontalPadding * 2),
      maxLines: 4,
    );

    _paintText(
      canvas,
      text: 'QiblaTime',
      style: GoogleFonts.amiri(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: tokens.primary,
      ),
      offset: const Offset(horizontalPadding, 1110),
      maxWidth: 220,
    );

    _paintText(
      canvas,
      text: 'Comparte tu progreso y sigue con constancia.',
      style: GoogleFonts.dmSans(
        fontSize: 22,
        color: tokens.textSecondary,
      ),
      offset: const Offset(horizontalPadding, 1160),
      maxWidth: 500,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('No se pudo generar la imagen de estadisticas.');
    }
    return byteData.buffer.asUint8List();
  }

  void _drawStatCard(
    Canvas canvas, {
    required QiblaTokens tokens,
    required Rect rect,
    required String value,
    required String label,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(rrect, Paint()..color = tokens.primaryBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = tokens.primaryBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _paintText(
      canvas,
      text: value,
      style: GoogleFonts.dmSans(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: tokens.primaryLight,
      ),
      offset: Offset(rect.left + 22, rect.top + 36),
      maxWidth: rect.width - 44,
    );
    _paintText(
      canvas,
      text: label,
      style: GoogleFonts.dmSans(
        fontSize: 20,
        height: 1.4,
        color: tokens.textSecondary,
      ),
      offset: Offset(rect.left + 22, rect.top + 102),
      maxWidth: rect.width - 44,
      maxLines: 2,
    );
  }

  double _paintText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required Offset offset,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '...',
    )..layout(maxWidth: maxWidth);

    textPainter.paint(canvas, offset);
    return textPainter.height;
  }
}
