import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../prayer_times/services/adhan_manager.dart';
import '../../prayer_times/services/prayer_service.dart';
import '../screens/adhan_selector_screen.dart';
import '../screens/support_tab.dart';

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
  bool adhanIsha = true;
  String selectedAdhan = 'adhan_makkah.mp3';
  int timeOffset = 0;
  bool isHanafi = false;
  CalculationMethod calculationMethod = CalculationMethod.muslim_world_league;

  static const _themes = [
    ('dark', 'Oscuro', 'Cielo antes del Fajr. Ideal para la noche.', Icons.dark_mode),
    ('light', 'Claro', 'Pergamino y arena. Para uso exterior.', Icons.light_mode),
    ('amoled', 'AMOLED', 'Negro puro y ahorro de bateria.', Icons.circle),
    ('deuteranopia', 'Deuteranopia', 'Sistema azul-amarillo mas accesible.', Icons.visibility),
    ('monochrome', 'Monocromo', 'Contraste por luminosidad.', Icons.contrast),
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
      adhanIsha = prefs.getBool('adhan_isha') ?? true;
      selectedAdhan = prefs.getString('selected_adhan') ?? 'adhan_makkah.mp3';
      timeOffset = prefs.getInt('time_offset') ?? 0;
      isHanafi = prefs.getBool('madhab_hanafi') ?? false;
      final methodIndex = prefs.getInt(AppConstants.keyCalculationMethod) ??
          CalculationMethod.muslim_world_league.index;
      calculationMethod = CalculationMethod.values[methodIndex];
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    ref.read(adhanManagerProvider).scheduleTodayAdhans();
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

  Future<void> _updateOffset(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('time_offset', newValue);
    ref.invalidate(prayerTimesProvider);
    if (!mounted) return;
    setState(() => timeOffset = newValue);
  }

  Future<void> _setMadhab(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('madhab_hanafi', value);
    ref.invalidate(madhabProvider);
    if (!mounted) return;
    setState(() => isHanafi = value);
  }

  Future<void> _setCalculationMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCalculationMethod, method.index);
    ref.invalidate(calculationMethodProvider);
    if (!mounted) return;
    setState(() => calculationMethod = method);
  }

  String _getAdhanDisplayName() {
    return selectedAdhan
        .replaceAll('adhan_', '')
        .replaceAll('.mp3', '')
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final themeName = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(tokens),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _buildSectionTitle('Apariencia', tokens),
                  ..._themes.map((theme) => _buildThemeTile(
                        tokens,
                        id: theme.$1,
                        title: theme.$2,
                        description: theme.$3,
                        icon: theme.$4,
                        selected: themeName == theme.$1,
                      )),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Notificaciones', tokens),
                  _buildToggleTile(tokens,
                      title: 'Fajr',
                      subtitle: 'Adhan al inicio de la oracion',
                      value: adhanFajr,
                      onChanged: (value) => _toggleSetting('adhan_fajr', value)),
                  _buildToggleTile(tokens,
                      title: 'Dhuhr',
                      subtitle: 'Recordatorio puntual',
                      value: adhanDhuhr,
                      onChanged: (value) => _toggleSetting('adhan_dhuhr', value)),
                  _buildToggleTile(tokens,
                      title: 'Asr',
                      subtitle: 'Notificacion activa',
                      value: adhanAsr,
                      onChanged: (value) => _toggleSetting('adhan_asr', value)),
                  _buildToggleTile(tokens,
                      title: 'Maghrib',
                      subtitle: 'Aviso al comenzar',
                      value: adhanMaghrib,
                      onChanged: (value) => _toggleSetting('adhan_maghrib', value)),
                  _buildToggleTile(tokens,
                      title: 'Isha',
                      subtitle: 'Ultima oracion del dia',
                      value: adhanIsha,
                      onChanged: (value) => _toggleSetting('adhan_isha', value)),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Calculo de horarios', tokens),
                  _buildInfoTile(tokens,
                      title: 'Metodo',
                      subtitle: 'Escoge el criterio de calculo',
                      value: calculationMethod.name.replaceAll('_', ' ').toUpperCase(),
                      onTap: _showCalculationMethodPicker),
                  _buildInfoTile(tokens,
                      title: 'Madhab (Asr)',
                      subtitle: 'Jurisprudencia usada en Asr',
                      value: isHanafi ? 'Hanafi' : 'Shafi',
                      onTap: () => _setMadhab(!isHanafi)),
                  _buildInfoTile(tokens,
                      title: 'Ajuste manual',
                      subtitle: 'Compensacion local',
                      value: '$timeOffset min',
                      trailing: _buildOffsetControl(tokens),
                      onTap: null),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Audio y soporte', tokens),
                  _buildInfoTile(tokens,
                      title: 'Biblioteca de Adhan',
                      subtitle: 'Actual: ${_getAdhanDisplayName()}',
                      value: 'Abrir',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdhanSelectorScreen(),
                          ),
                        );
                        _loadSettings();
                      }),
                  _buildInfoTile(tokens,
                      title: 'Apoya QiblaTime',
                      subtitle: 'Sadaqah Jariyah y ayuda al proyecto',
                      value: 'Ver',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupportTab(),
                          ),
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QiblaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajustes',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
                Text(
                  'الاعدادات · Preferencias y apariencia',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              'v2',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tokens.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, QiblaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          color: tokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    QiblaTokens tokens, {
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => ref.read(themeControllerProvider.notifier).setTheme(id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? tokens.activeBg : tokens.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tokens.activeBorder : tokens.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.bgSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border),
                ),
                child: Icon(icon, color: tokens.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        height: 1.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? tokens.primary : Colors.transparent,
                  border: Border.all(color: selected ? tokens.primary : tokens.borderMed),
                ),
                child: selected
                    ? Icon(Icons.check, size: 12, color: tokens.bgPage)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    QiblaTokens tokens, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: tokens.textSecondary,
                    )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: tokens.bgPage,
            activeTrackColor: tokens.primary,
            inactiveTrackColor: tokens.bgSurface2,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    QiblaTokens tokens, {
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: tokens.textPrimary,
              fontWeight: FontWeight.w500,
            )),
        subtitle: Text(subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: tokens.textSecondary,
            )),
        trailing: trailing ??
            Text(value,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.primary,
                  fontWeight: FontWeight.w500,
                )),
      ),
    );
  }

  Widget _buildOffsetControl(QiblaTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _updateOffset(timeOffset - 1),
          icon: Icon(Icons.remove_circle_outline, color: tokens.textSecondary),
        ),
        Text(
          '$timeOffset',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.primary,
          ),
        ),
        IconButton(
          onPressed: () => _updateOffset(timeOffset + 1),
          icon: Icon(Icons.add_circle_outline, color: tokens.primary),
        ),
      ],
    );
  }

  Future<void> _showCalculationMethodPicker() async {
    final tokens = QiblaThemes.current;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: CalculationMethod.values.map((method) {
            final selected = method == calculationMethod;
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: selected ? tokens.activeBg : tokens.bgSurface2,
              title: Text(
                method.name.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: selected ? tokens.primaryLight : tokens.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: selected ? Icon(Icons.check, color: tokens.primary) : null,
              onTap: () async {
                await _setCalculationMethod(method);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
