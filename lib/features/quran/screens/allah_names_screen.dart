import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../models/allah_name.dart';
import '../services/allah_names_service.dart';

class AllahNamesScreen extends ConsumerWidget {
  const AllahNamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final namesAsync = ref.watch(allahNamesProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.allahNamesTitle,
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: namesAsync.when(
        data: (names) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: names.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  l10n.allahNamesIntro,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.6,
                    color: tokens.textPrimary,
                  ),
                ),
              );
            }

            final name = names[index - 1];
            return _AllahNameCard(name: name);
          },
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.allahNamesLoadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllahNameCard extends StatelessWidget {
  const _AllahNameCard({required this.name});

  final AllahName name;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = name.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: tokens.primaryBg,
                foregroundColor: tokens.primary,
                child: Text(
                  '${name.id}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                name.arabic,
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  color: tokens.primaryLight,
                ),
              ),
            ],
          ),
          if (!isArabicOnly) ...[
            const SizedBox(height: 10),
            Text(
              name.name,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            if (name.transliteration.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name.transliteration,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          if (name.hasDescription) ...[
            const SizedBox(height: 4),
            Text(
              name.description,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.6,
                color: tokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DhikrScreen(
                      initialPhrase: DhikrPhrase(
                        arabic: name.arabic,
                        transliteration: name.transliteration,
                        meaning: name.name,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.repeat_rounded),
              label: Text(l10n.allahNamesUseInTasbih),
            ),
          ),
        ],
      ),
    );
  }
}
