import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/accessibility_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../prayer_times/services/prayer_cache_service.dart';
import '../../prayer_times/services/prayer_service.dart';
import '../../prayer_times/services/travel_mode_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool adhanFajr = true;
  bool adhanDhuhr = true;
  bool adhanAsr = true;
  bool adhanMaghrib = true;
  bool adhanIsha = false;
  bool haptics = true;
  bool autoLocation = true;
  bool travelerMode = true;
  int timeOffset = 0;
  bool isHanafi = false;
  CalculationMethod calculationMethod = CalculationMethod.muslim_world_league;

  static const _themes = [
    ('dark', 'Oscuro', 'Cielo antes del Fajr', '🌙'),
    ('light', 'Claro', 'Para uso en exteriores', '☀️'),
    ('amoled', 'AMOLED', 'Negro puro, ahorra bateria', '⚫'),
    ('deuteranopia', 'Deuteranopia', 'Sin rojo/verde', '👁'),
    ('monochrome', 'Monocromia', 'Acromatopsia y baja vision', '⬜'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      adhanFajr = prefs.getBool('adhan_fajr') ?? true;
      adhanDhuhr = prefs.getBool('adhan_dhuhr') ?? true;
      adhanAsr = prefs.getBool('adhan_asr') ?? true;
      adhanMaghrib = prefs.getBool('adhan_maghrib') ?? true;
      adhanIsha = prefs.getBool('adhan_isha') ?? false;
      travelerMode = prefs.getBool(AppConstants.keyTravelerModeEnabled) ?? true;
      timeOffset = prefs.getInt('time_offset') ?? 0;
      isHanafi = prefs.getBool('madhab_hanafi') ?? false;
      final methodIndex = prefs.getInt(AppConstants.keyCalculationMethod) ?? CalculationMethod.muslim_world_league.index;
      calculationMethod = CalculationMethod.values[methodIndex];
    });
  }

  Future<void> _toggleBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      switch (key) {
        case 'adhan_fajr':
          adhanFajr = value;
          break;
        case 'adhan_dhuhr':
          adhanDhuhr = value;
          break;
        case 'adhan_asr':
          adhanAsr = value;
          break;
        case 'adhan_maghrib':
          adhanMaghrib = value;
          break;
        case 'adhan_isha':
          adhanIsha = value;
          break;
      }
    });
  }

  Future<void> _toggleTravelerMode(bool value) async {
    await ref.read(travelModeServiceProvider).setEnabled(value);
    if (!mounted) return;
    setState(() => travelerMode = value);
    ref.invalidate(travelerModeEnabledProvider);
  }

  Future<void> _setTheme(String theme) async {
    await ref.read(themeControllerProvider.notifier).setTheme(theme);
  }

  Future<void> _setCalculationMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCalculationMethod, method.index);
    ref.invalidate(calculationMethodProvider);
    if (!mounted) return;
    setState(() => calculationMethod = method);
  }

  Future<void> _setMadhab(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('madhab_hanafi', value);
    ref.invalidate(madhabProvider);
    if (!mounted) return;
    setState(() => isHanafi = value);
  }

  Future<void> _updateOffset(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('time_offset', newValue);
    if (!mounted) return;
    setState(() => timeOffset = newValue);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final themeName = ref.watch(themeControllerProvider);
    final accessibility = ref.watch(accessibilityControllerProvider);
    final lastLocation = ref.watch(lastLocationLabelProvider).valueOrNull;
    final recentLocations = ref.watch(recentLocationsProvider).valueOrNull ?? const [];
    final cacheStatus = ref.watch(prayerCacheStatusProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Ajustes', style: GoogleFonts.amiri(fontSize: 26, color: tokens.primary, fontWeight: FontWeight.bold)),
            Text('الإعدادات', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
            const SizedBox(height: 16),
            _buildProfileCard(tokens),
            const SizedBox(height: 16),
            _buildSectionTitle(tokens, 'Apariencia'),
            ..._themes.map((theme) => _buildThemeTile(tokens, themeName, theme.$1, theme.$2, theme.$3, theme.$4)),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Accesibilidad'),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamano de texto', style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Escala actual: ${accessibility.fontScale.toStringAsFixed(1)}x', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                  Slider(
                    value: accessibility.fontScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${accessibility.fontScale.toStringAsFixed(1)}x',
                    onChanged: (value) => ref.read(accessibilityControllerProvider.notifier).setFontScale(value),
                  ),
                ],
              ),
            ),
            _buildSimpleToggleTile(tokens, 'Alto contraste', 'Mejora legibilidad en toda la app', accessibility.highContrast, (v) => ref.read(accessibilityControllerProvider.notifier).setHighContrast(v)),
            _buildSimpleToggleTile(tokens, 'Usar negrita del sistema', 'Respeta la preferencia de VoiceOver/TalkBack', accessibility.useSystemBoldText, (v) => ref.read(accessibilityControllerProvider.notifier).setUseSystemBoldText(v)),
            _buildValueTile(
              tokens,
              'Restablecer accesibilidad',
              'Reset',
              onTap: () => ref.read(accessibilityControllerProvider.notifier).reset(),
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Notificaciones · Adhan'),
            _buildToggleTile(tokens, 'Fajr', '6:12 · Adhan Al-Aqsa', adhanFajr, (v) => _toggleBool('adhan_fajr', v)),
            _buildToggleTile(tokens, 'Dhuhr', '13:45 · Adhan Makkah', adhanDhuhr, (v) => _toggleBool('adhan_dhuhr', v)),
            _buildToggleTile(tokens, 'Asr', '17:14 · Adhan Makkah', adhanAsr, (v) => _toggleBool('adhan_asr', v)),
            _buildToggleTile(tokens, 'Maghrib', '19:52 · Adhan Al-Aqsa', adhanMaghrib, (v) => _toggleBool('adhan_maghrib', v)),
            _buildToggleTile(tokens, 'Isha', '21:28 · Adhan Makkah', adhanIsha, (v) => _toggleBool('adhan_isha', v)),
            _buildSimpleToggleTile(tokens, 'Vibracion haptica', 'En Tasbih y notificaciones', haptics, (v) => setState(() => haptics = v)),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Calculo de horarios'),
            _buildValueTile(tokens, 'Metodo', calculationMethod.name.replaceAll('_', ' ').toUpperCase(), onTap: _showMethodSheet),
            _buildValueTile(tokens, 'Madhab (Asr)', isHanafi ? 'Hanafi' : 'Shafi', onTap: () => _setMadhab(!isHanafi)),
            _buildValueTile(tokens, 'Ajuste manual', '±$timeOffset min', trailing: _offsetButtons(tokens)),
            _buildSimpleToggleTile(tokens, 'Ubicacion', 'GPS automatico', autoLocation, (v) => setState(() => autoLocation = v)),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Modo viajero'),
            _buildSimpleToggleTile(tokens, 'Modo Viajero', 'Detecta cambios >50 km y actualiza horarios', travelerMode, _toggleTravelerMode),
            _buildValueTile(tokens, 'Ultima ubicacion', lastLocation ?? 'Sin datos'),
            if (recentLocations.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ultimas ubicaciones', style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...recentLocations.take(5).map((location) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• ${location.label}', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                        )),
                  ],
                ),
              ),
            _buildSectionTitle(tokens, 'Cache inteligente'),
            _buildValueTile(tokens, 'Cache valido hasta', cacheStatus.validUntil?.toLocal().toString().substring(0, 16) ?? 'Sin cache'),
            _buildValueTile(tokens, 'Entradas cacheadas', '${cacheStatus.entryCount}'),
            _buildValueTile(
              tokens,
              'Limpiar cache',
              'Borrar',
              onTap: () async {
                await ref.read(prayerCacheServiceProvider).clear();
                ref.invalidate(prayerCacheStatusProvider);
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Sadaqah · Apoyo'),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Row(
                children: [
                  const Text('💛', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apoya el desarrollo', style: GoogleFonts.dmSans(fontSize: 13, color: tokens.primaryLight, fontWeight: FontWeight.w500)),
                        Text('Cada donacion es una Sadaqah Jariya', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildValueTile(tokens, 'Sadaqah tracker', '→'),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Acerca de'),
            _buildValueTile(tokens, 'Version', '3.0.0'),
            _buildValueTile(tokens, 'Licencias open source', '→'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(QiblaTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.primaryBg,
              border: Border.all(color: tokens.primaryBorder, width: 2),
            ),
            child: const Center(child: Text('🕌', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Abdullah Garcia', style: GoogleFonts.dmSans(fontSize: 15, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _stat(tokens, '14', 'racha'),
                    const SizedBox(width: 12),
                    _stat(tokens, '487', 'oraciones'),
                    const SizedBox(width: 12),
                    _stat(tokens, '3.2k', 'tasbih'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(QiblaTokens tokens, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.dmSans(fontSize: 16, color: tokens.primaryLight, fontWeight: FontWeight.w500)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: tokens.textSecondary)),
      ],
    );
  }

  Widget _buildSectionTitle(QiblaTokens tokens, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(text.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.5, color: tokens.textSecondary)),
    );
  }

  Widget _buildThemeTile(QiblaTokens tokens, String themeName, String id, String title, String subtitle, String emoji) {
    final selected = themeName == id;
    return InkWell(
      onTap: () => _setTheme(id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? tokens.activeBg : tokens.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tokens.activeBorder : tokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.bgSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? tokens.primary : Colors.transparent,
                border: Border.all(color: selected ? tokens.primary : tokens.borderMed),
              ),
              child: selected ? Icon(Icons.check, size: 10, color: tokens.bgPage) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(QiblaTokens tokens, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return _buildSimpleToggleTile(tokens, title, subtitle, value, onChanged);
  }

  Widget _buildSimpleToggleTile(QiblaTokens tokens, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary)),
                Text(subtitle, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.bgPage,
            activeTrackColor: tokens.primary,
            inactiveTrackColor: tokens.bgSurface2,
          ),
        ],
      ),
    );
  }

  Widget _buildValueTile(QiblaTokens tokens, String title, String value, {VoidCallback? onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary)),
        trailing: trailing ?? Text(value, style: GoogleFonts.dmSans(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _offsetButtons(QiblaTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () => _updateOffset(timeOffset - 1), icon: Icon(Icons.remove_circle_outline, color: tokens.textSecondary)),
        Text('±$timeOffset', style: GoogleFonts.dmSans(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w500)),
        IconButton(onPressed: () => _updateOffset(timeOffset + 1), icon: Icon(Icons.add_circle_outline, color: tokens.primary)),
      ],
    );
  }

  Future<void> _showMethodSheet() async {
    final tokens = QiblaThemes.current;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: CalculationMethod.values.map((method) {
            final selected = method == calculationMethod;
            return ListTile(
              tileColor: selected ? tokens.activeBg : tokens.bgSurface2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text(method.name.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.dmSans(color: selected ? tokens.primaryLight : tokens.textPrimary)),
              trailing: selected ? Icon(Icons.check, color: tokens.primary) : null,
              onTap: () async {
                await _setCalculationMethod(method);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
