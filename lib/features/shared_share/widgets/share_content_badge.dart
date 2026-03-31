import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareContentBadge extends StatelessWidget {
  const ShareContentBadge({
    super.key,
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.trim().toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.8,
          color: accentColor,
        ),
      ),
    );
  }
}
