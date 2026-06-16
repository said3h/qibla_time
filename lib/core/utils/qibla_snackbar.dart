import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

void showQiblaSnackBar(
  BuildContext context, {
  required String message,
  IconData? icon = Icons.check_circle_rounded,
  Duration duration = const Duration(milliseconds: 1800),
}) {
  showQiblaSnackBarWithMessenger(
    context,
    messenger: ScaffoldMessenger.of(context),
    message: message,
    icon: icon,
    duration: duration,
  );
}

void showQiblaSnackBarWithMessenger(
  BuildContext context, {
  required ScaffoldMessengerState messenger,
  required String message,
  IconData? icon = Icons.check_circle_rounded,
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final tokens = QiblaThemes.current;
  final availableWidth = MediaQuery.sizeOf(context).width - 40;
  final snackBarWidth = math.max(220.0, math.min(340.0, availableWidth));
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: snackBarWidth,
      elevation: 14,
      duration: duration,
      backgroundColor: tokens.bgSurface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.primaryBorder, width: 1),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: tokens.primary,
              size: 19,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
