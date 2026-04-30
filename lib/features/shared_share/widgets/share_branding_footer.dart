import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareBrandingFooter extends StatelessWidget {
  const ShareBrandingFooter({
    super.key,
    required this.accentColor,
    required this.mutedColor,
    required this.fontSize,
  });

  static const _logoAsset = 'assets/images/app/logo.svg';

  final Color accentColor;
  final Color mutedColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: mutedColor.withValues(alpha: 0.22),
                thickness: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset(
                _logoAsset,
                width: fontSize * 1.25,
                height: fontSize * 1.25,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Divider(
                color: mutedColor.withValues(alpha: 0.22),
                thickness: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Qibla Time',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: fontSize * 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
