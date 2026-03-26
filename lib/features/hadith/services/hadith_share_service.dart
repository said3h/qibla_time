import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../models/hadith.dart';

final hadithShareServiceProvider = Provider<HadithShareService>((ref) {
  return HadithShareService();
});

class HadithShareService {
  Future<void> shareHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens,
  ) async {
    final bytes = await _renderCard(hadith, tokens);
    final directory = await Directory.systemTemp.createTemp('qiblatime_hadith');
    final file = File('${directory.path}/hadith_${hadith.id}.png');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hadith diario de QiblaTime',
    );
  }

  Future<Uint8List> _renderCard(Hadith hadith, QiblaTokens tokens) async {
    const width = 1080.0;
    const height = 1350.0;
    const horizontalPadding = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = const Rect.fromLTWH(0, 0, width, height);

    final background = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(width, height),
        [
          tokens.bgPage,
          tokens.primaryBg,
        ],
      );
    canvas.drawRect(bounds, background);

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 72, width - 144, height - 144),
      const Radius.circular(44),
    );
    canvas.drawRRect(
      cardRect,
      Paint()..color = tokens.bgSurface,
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = tokens.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(120, 120, 240, 64),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = tokens.primaryBg,
    );

    _paintText(
      canvas,
      text: 'HADITH DIARIO',
      style: GoogleFonts.dmSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: tokens.primary,
      ),
      offset: const Offset(154, 136),
      maxWidth: 180,
    );

    double cursorY = 230;
    cursorY += _paintText(
      canvas,
      text: hadith.arabic,
      style: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 54,
        height: 1.9,
      ).copyWith(color: tokens.textPrimary),
      offset: Offset(horizontalPadding, cursorY),
      maxWidth: width - (horizontalPadding * 2),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLines: 7,
    );

    cursorY += 30;
    cursorY += _paintText(
      canvas,
      text: hadith.translation,
      style: GoogleFonts.dmSans(
        fontSize: 30,
        height: 1.7,
        color: tokens.textPrimary,
      ),
      offset: Offset(horizontalPadding, cursorY),
      maxWidth: width - (horizontalPadding * 2),
      maxLines: 9,
    );

    cursorY += 24;
    cursorY += _paintText(
      canvas,
      text: '${hadith.reference} - ${hadith.category}',
      style: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: tokens.primary,
      ),
      offset: Offset(horizontalPadding, cursorY),
      maxWidth: width - (horizontalPadding * 2),
      maxLines: 2,
    );

    const footerTop = height - 190;
    canvas.drawLine(
      const Offset(horizontalPadding, footerTop),
      const Offset(width - horizontalPadding, footerTop),
      Paint()
        ..color = tokens.borderMed
        ..strokeWidth = 2,
    );

    _paintText(
      canvas,
      text: 'Compartido desde QiblaTime',
      style: GoogleFonts.dmSans(
        fontSize: 24,
        color: tokens.textSecondary,
      ),
      offset: const Offset(horizontalPadding, footerTop + 36),
      maxWidth: 420,
    );

    _paintText(
      canvas,
      text: hadith.grade,
      style: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: tokens.primary,
      ),
      offset: Offset(width - horizontalPadding - 180, footerTop + 36),
      maxWidth: 180,
      textAlign: TextAlign.right,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('No se pudo generar la imagen del hadith.');
    }
    return byteData.buffer.asUint8List();
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
