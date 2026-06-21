import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/share_sheet_origin.dart';
import '../../../l10n/l10n.dart';
import '../services/app_store_links.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.supportScreenTitle,
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
            l10n.supportScreenThankYou,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.supportScreenBody,
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
            title: l10n.supportScreenRateTitle,
            description: l10n.supportScreenRateBody,
            onTap: () {
              AppStoreLinks.openStoreListing();
            },
          ),
          _SupportInfoCard(
            icon: Icons.share_rounded,
            title: l10n.supportScreenShareTitle,
            description: l10n.supportScreenShareBody,
            onTap: () {
              Share.share(
                AppStoreLinks.shareUrl,
                sharePositionOrigin: qiblaShareSheetOrigin,
              );
            },
          ),
          const _SupportInfoCard(
            icon: Icons.mail_outline_rounded,
            title: 'Contact Support',
            description: 'support.qiblatime@gmail.com',
            onTap: _openSupportEmail,
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
              l10n.supportScreenQuote,
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

  static Future<void> _openSupportEmail() async {
    const subject = 'Qibla Time Support';
    const body = '''
Hello,

I need help with Qibla Time.

Device:
OS Version:

Description:
''';
    final uri = Uri(
      scheme: 'mailto',
      path: 'support.qiblatime@gmail.com',
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SupportInfoCard extends StatelessWidget {
  const _SupportInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
          ),
        ),
      ),
    );
  }
}
