import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../services/hadith_offline_service.dart';

/// Pantalla informativa sobre la disponibilidad sin conexión de hadices
class HadithOfflineScreen extends ConsumerStatefulWidget {
  const HadithOfflineScreen({super.key});

  @override
  ConsumerState<HadithOfflineScreen> createState() => _HadithOfflineScreenState();
}

class _HadithOfflineScreenState extends ConsumerState<HadithOfflineScreen> {
  final HadithOfflineService _offlineService = HadithOfflineService();
  HadithOfflineStatus? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final status = await _offlineService.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.hadithOfflineTitle,
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tokens.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tarjeta de estado general
                _buildStatusCard(tokens),
                const SizedBox(height: 16),

                // Información
                _buildInfoCard(tokens),
                const SizedBox(height: 16),

                // Lista de colecciones
                Text(
                  l10n.hadithOfflineCollectionsTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                ...HadithOfflineService.availableCollections.entries.map(
                  (entry) => _buildCollectionTile(tokens, entry.value),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(QiblaTokens tokens) {
    final l10n = context.l10n;
    final progress = _status!.downloadProgress * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.primary.withOpacity(0.15),
            tokens.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _status!.isFullyOffline ? Icons.cloud_done : Icons.cloud_download,
                color: tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hadithOfflineIncludedTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.hadithOfflineIncludedSubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_status!.totalCollections}',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _status!.downloadProgress,
              backgroundColor: tokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.hadithOfflineAvailability(progress.toStringAsFixed(0)),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(QiblaTokens tokens) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: tokens.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.hadithOfflineInfoBody,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTile(
    QiblaTokens tokens,
    String name,
  ) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  l10n.hadithOfflineAvailable,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.green,
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
