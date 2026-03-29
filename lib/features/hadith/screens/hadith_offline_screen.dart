import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../services/hadith_offline_service.dart';

/// Pantalla para gestionar la disponibilidad offline de hadices
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

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Hadices Offline',
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
                  'COLECCIONES DISPONIBLES',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                ...HadithOfflineService.availableCollections.entries.map(
                  (entry) => _buildCollectionTile(tokens, entry.key, entry.value),
                ),

                const SizedBox(height: 32),

                // Botón de sincronizar todo
                if (!_status!.isFullyOffline)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _syncAll,
                      icon: const Icon(Icons.download),
                      label: const Text('Sincronizar Todo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(QiblaTokens tokens) {
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
                      _status!.isFullyOffline
                          ? 'Todo Disponible Offline'
                          : 'Sincronización Parcial',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      'Última sync: ${_status!.lastSyncLabel}',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_status!.downloadedCount}/${_status!.totalCollections}',
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
            '${progress.toStringAsFixed(0)}% completado',
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
              'Todos los hadices ya están en tu dispositivo. Esta pantalla muestra el estado de sincronización.',
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
    String key,
    String name,
  ) {
    final isDownloaded = _status!.downloadedCollections.contains(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDownloaded ? tokens.primary.withOpacity(0.3) : tokens.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDownloaded
                  ? Colors.green.withOpacity(0.1)
                  : tokens.border.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
              color: isDownloaded ? Colors.green : tokens.textSecondary,
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
                  isDownloaded ? 'Disponible offline' : 'No sincronizado',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: isDownloaded ? Colors.green : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDownloaded)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              onPressed: () => _removeCollection(key),
              tooltip: 'Eliminar de offline',
            ),
        ],
      ),
    );
  }

  Future<void> _syncAll() async {
    await _offlineService.markAllCollectionsAsDownloaded();
    await _loadStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Todos los hadices disponibles offline'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _removeCollection(String key) async {
    await _offlineService.removeCollection(key);
    await _loadStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Colección eliminada de offline'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
