import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibla_time/core/theme/local_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import 'nearby_mosques_screen.dart';

class NearbyPlacesScreen extends ConsumerWidget {
  const NearbyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              l10n.nearbyPlacesTitle,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 30,
                height: 1.1,
                color: tokens.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.nearbyPlacesSubtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.5,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _NearbyCategoryCard(
              icon: Icons.mosque_outlined,
              title: l10n.nearbyMosques,
              subtitle: l10n.nearbyMosquesSubtitle,
              isAvailable: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NearbyMosquesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _NearbyCategoryCard(
              icon: Icons.restaurant_menu_outlined,
              title: l10n.nearbyHalalRestaurants,
              subtitle: l10n.nearbyHalalRestaurantsSubtitle,
              isAvailable: false,
            ),
            const SizedBox(height: 12),
            _NearbyCategoryCard(
              icon: Icons.storefront_outlined,
              title: l10n.nearbyHalalButchers,
              subtitle: l10n.nearbyHalalButchersSubtitle,
              isAvailable: false,
            ),
            const SizedBox(height: 18),
            _OsmAttribution(tokens: tokens),
          ],
        ),
      ),
    );
  }
}

class _NearbyCategoryCard extends StatelessWidget {
  const _NearbyCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isAvailable,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      label: title,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tokens.bgSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isAvailable ? tokens.primaryBorder : tokens.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAvailable ? tokens.primaryBg : tokens.bgSurface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? tokens.primary : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (!isAvailable)
                          _ComingSoonBadge(label: l10n.nearbyComingSoon),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        height: 1.45,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAvailable) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: tokens.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.nearbyOsmAttribution,
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        color: tokens.textMuted,
      ),
    );
  }
}
