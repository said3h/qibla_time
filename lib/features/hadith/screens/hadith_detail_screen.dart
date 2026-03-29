import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../hadith/models/hadith.dart';
import '../../hadith/screens/hadith_library_screen.dart';
import '../../hadith/services/hadith_service.dart';
import '../../hadith/services/hadith_share_service.dart';

/// Pantalla de detalle de un hadiz específico
/// Muestra texto completo, referencias, y opciones avanzadas
class HadithDetailScreen extends ConsumerStatefulWidget {
  const HadithDetailScreen({
    super.key,
    required this.hadith,
  });

  final Hadith hadith;

  @override
  ConsumerState<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends ConsumerState<HadithDetailScreen> {
  bool _showArabic = true;
  bool _showTranslation = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await ref
        .read(hadithServiceProvider)
        .isFavorite(widget.hadith.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final hadith = widget.hadith;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Detalle del Hadiz',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        actions: [
          // Botón de favorito
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : tokens.textPrimary,
            ),
            onPressed: _toggleFavorite,
          ),
          // Menú de compartir
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'copy', child: Text('Copiar texto')),
              const PopupMenuItem(value: 'share_text', child: Text('Compartir texto')),
              const PopupMenuItem(value: 'share_image', child: Text('Compartir imagen')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header con colección y grado
          _buildHeader(tokens, hadith),
          const SizedBox(height: 20),

          // Texto en árabe
          if (_showArabic) ...[
            _buildSection(
              tokens: tokens,
              title: 'Texto en Árabe',
              icon: Icons.text_fields,
              child: _buildArabicText(tokens, hadith.arabic),
            ),
            const SizedBox(height: 16),
          ],

          // Traducción
          if (_showTranslation) ...[
            _buildSection(
              tokens: tokens,
              title: 'Traducción al Español',
              icon: Icons.translate,
              child: _buildTranslationText(tokens, hadith.translation),
            ),
            const SizedBox(height: 16),
          ],

          // Referencia y grado
          _buildReferenceCard(tokens, hadith),
          const SizedBox(height: 16),

          // Categoría
          _buildCategoryCard(tokens, hadith.category),
          const SizedBox(height: 16),

          // Acciones rápidas
          _buildQuickActions(tokens, hadith),
          const SizedBox(height: 24),

          // Información adicional
          _buildInfoCard(tokens),
          const SizedBox(height: 16),

          // Botones de toggle
          _buildToggleButtons(tokens),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(tokens),
    );
  }

  Widget _buildHeader(QiblaTokens tokens, Hadith hadith) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCollectionColor(hadith.reference).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 14,
                          color: _getCollectionColor(hadith.reference),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _extractCollection(hadith.reference),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getCollectionColor(hadith.reference),
                          ),
                        ),
                      ],
                    ),
                    if (_getArabicCollectionLabel(
                          _extractCollection(hadith.reference),
                        ) !=
                        null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getArabicCollectionLabel(
                            _extractCollection(hadith.reference),
                          )!,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getCollectionColor(hadith.reference),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(hadith.grade).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hadith.grade,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getGradeColor(hadith.grade),
                      ),
                    ),
                    if (_getArabicGradeLabel(hadith.grade) != null)
                      Text(
                        _getArabicGradeLabel(hadith.grade)!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getGradeColor(hadith.grade),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ID: ${hadith.id}',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required QiblaTokens tokens,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildArabicText(QiblaTokens tokens, String arabic) {
    return SelectableText(
      arabic,
      textAlign: TextAlign.right,
      style: GoogleFonts.amiri(
        fontSize: 24,
        height: 2.0,
        color: tokens.textPrimary,
      ),
    );
  }

  Widget _buildTranslationText(QiblaTokens tokens, String translation) {
    return SelectableText(
      translation,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.8,
        color: tokens.textPrimary,
      ),
    );
  }

  Widget _buildReferenceCard(QiblaTokens tokens, Hadith hadith) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, size: 18, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                'Referencia',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_getArabicReferenceLabel(hadith.reference) != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _getArabicReferenceLabel(hadith.reference)!,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            hadith.reference,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Grado: ${hadith.grade}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              if (_getArabicGradeLabel(hadith.grade) != null)
                Text(
                  _getArabicGradeLabel(hadith.grade)!,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getGradeColor(hadith.grade),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(QiblaTokens tokens, String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline, size: 18, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                'Categoría / Tema',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.isNotEmpty ? category : 'Sin categoría específica',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          if (_getArabicCategoryLabel(category) != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _getArabicCategoryLabel(category)!,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(QiblaTokens tokens, Hadith hadith) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _QuickActionButton(
          icon: Icons.copy_all_outlined,
          label: 'Copiar',
          color: tokens.primary,
          onTap: () => _copyToClipboard(hadith),
        ),
        _QuickActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          color: Colors.green,
          onTap: () => _shareHadith(hadith, tokens),
        ),
        _QuickActionButton(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          label: _isFavorite ? 'Guardado' : 'Guardar',
          color: _isFavorite ? Colors.red : Colors.orange,
          onTap: _toggleFavorite,
        ),
        _QuickActionButton(
          icon: Icons.open_in_new,
          label: 'Biblioteca',
          color: Colors.blue,
          onTap: _openLibrary,
        ),
      ],
    );
  }

  Widget _buildInfoCard(QiblaTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                'Información',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Este hadiz forma parte de la colección completa de 1,954 hadices en español con tildes correctas. Fuente: HadeethEnc.com',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              height: 1.6,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(QiblaTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showArabic = !_showArabic),
            icon: Icon(
              _showArabic ? Icons.visibility : Icons.visibility_off,
              size: 16,
            ),
            label: Text(_showArabic ? 'Ocultar Árabe' : 'Mostrar Árabe'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
            icon: Icon(
              _showTranslation ? Icons.visibility : Icons.visibility_off,
              size: 16,
            ),
            label: Text(_showTranslation ? 'Ocultar Español' : 'Mostrar Español'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(QiblaTokens tokens) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareHadith(widget.hadith, tokens),
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.white : tokens.textPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _isFavorite ? Colors.red : tokens.bgSurface,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Acciones ──────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    await ref.read(hadithServiceProvider).toggleFavorite(widget.hadith.id);
    setState(() {
      _isFavorite = !_isFavorite;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Hadiz guardado en favoritos' : 'Hadiz eliminado de favoritos'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyToClipboard(Hadith hadith) async {
    final text = '${hadith.arabic}\n\n${hadith.translation}\n\n— ${hadith.reference}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareHadith(Hadith hadith, QiblaTokens tokens) async {
    try {
      await ref.read(hadithShareServiceProvider).shareHadithAsText(hadith);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir el hadiz')),
      );
    }
  }

  Future<void> _handleMenuAction(String value) async {
    switch (value) {
      case 'copy':
        _copyToClipboard(widget.hadith);
        break;
      case 'share_text':
        await ref.read(hadithShareServiceProvider).shareHadithAsText(widget.hadith);
        break;
      case 'share_image':
        try {
          await ref.read(hadithShareServiceProvider).shareHadithAsImage(
                widget.hadith,
                QiblaThemes.current,
              );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo generar la imagen')),
          );
        }
        break;
    }
  }

  void _openLibrary() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => const HadithLibraryScreen()),
    );
  }

  // ── Utilidades ──────────────────────────────────────────────

  Color _getCollectionColor(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) return Colors.green;
    if (refLower.contains('muslim')) return Colors.blue;
    if (refLower.contains('tirmidhi')) return Colors.orange;
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) return Colors.purple;
    if (refLower.contains('nasai')) return Colors.teal;
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) return Colors.indigo;
    if (refLower.contains('malik') || refLower.contains('muwatta')) return Colors.amber;
    if (refLower.contains('ahmad')) return Colors.brown;
    return Colors.grey;
  }

  Color _getGradeColor(String grade) {
    if (grade == 'Sahih') return Colors.green;
    if (grade == 'Hasan') return Colors.orange;
    if (grade == 'Da\'if') return Colors.red;
    return Colors.grey;
  }

  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) return 'Bukhari';
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) return 'Abu Dawud';
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) return 'Ibn Majah';
    if (refLower.contains('malik') || refLower.contains('muwatta')) return 'Malik';
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Otros';
  }

  String? _getArabicCollectionLabel(String collection) {
    switch (collection.trim().toLowerCase()) {
      case 'bukhari':
        return 'البخاري';
      case 'muslim':
        return 'مسلم';
      case 'tirmidhi':
        return 'الترمذي';
      case 'abu dawud':
        return 'أبو داود';
      case 'nasai':
        return 'النسائي';
      case 'ibn majah':
        return 'ابن ماجه';
      case 'malik':
        return 'مالك';
      case 'ahmad':
        return 'أحمد';
      default:
        return null;
    }
  }

  String? _getArabicReferenceLabel(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) {
      return 'رواه البخاري';
    }
    if (refLower.contains('muslim')) {
      return 'رواه مسلم';
    }
    if (refLower.contains('tirmidhi')) {
      return 'رواه الترمذي';
    }
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) {
      return 'رواه أبو داود';
    }
    if (refLower.contains('nasai')) {
      return 'رواه النسائي';
    }
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) {
      return 'رواه ابن ماجه';
    }
    if (refLower.contains('malik') || refLower.contains('muwatta')) {
      return 'رواه مالك';
    }
    if (refLower.contains('ahmad')) {
      return 'رواه أحمد';
    }
    return null;
  }

  String? _getArabicGradeLabel(String grade) {
    switch (grade.trim().toLowerCase()) {
      case 'sahih':
        return 'صحيح';
      case 'hasan':
        return 'حسن';
      case 'da\'if':
      case 'daif':
        return 'ضعيف';
      default:
        return null;
    }
  }

  String? _getArabicCategoryLabel(String category) {
    switch (category.trim().toLowerCase()) {
      case 'adab':
        return 'الأدب';
      case 'amor de alá':
      case 'amor de ala':
        return 'محبة الله';
      case 'autorreflexión':
      case 'autorreflexion':
        return 'محاسبة النفس';
      case 'ayuno':
        return 'الصيام';
      case 'carácter':
      case 'caracter':
        return 'حسن الخلق';
      case 'caridad':
        return 'الصدقة';
      case 'compasión':
      case 'compasion':
        return 'الرحمة';
      case 'conocimiento':
        return 'العلم';
      case 'constancia':
        return 'الثبات';
      case 'corazón':
      case 'corazon':
        return 'القلب';
      case 'dhikr':
        return 'الذكر';
      case 'dua':
        return 'الدعاء';
      case 'familia':
        return 'الأسرة';
      case 'fraternidad':
        return 'الأخوة';
      case 'gratitud':
        return 'الشكر';
      case 'haya':
        return 'الحياء';
      case 'honestidad':
        return 'الأمانة';
      case 'ihsan':
        return 'الإحسان';
      case 'intenciones':
        return 'النيات';
      case 'istighfar':
        return 'الاستغفار';
      case 'justicia':
        return 'العدل';
      case 'lengua':
        return 'اللسان';
      case 'mezquita':
        return 'المسجد';
      case 'misericordia':
        return 'الرحمة';
      case 'paciencia':
        return 'الصبر';
      case 'purificación':
      case 'purificacion':
        return 'الطهارة';
      case 'quran':
        return 'القرآن';
      case 'rizq':
      case 'sustento':
        return 'الرزق';
      case 'salah':
        return 'الصلاة';
      case 'seguridad':
        return 'الأمان';
      case 'servicio':
        return 'خدمة الناس';
      case 'sinceridad':
        return 'الإخلاص';
      case 'taqwa':
        return 'التقوى';
      case 'zuhd':
        return 'الزهد';
      default:
        return null;
    }
  }
}

// ── Widget de Acción Rápida ───────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
