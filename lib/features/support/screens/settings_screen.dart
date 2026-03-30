import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/accessibility_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../hafiz/services/hafiz_service.dart';
import '../../hadith/services/hadith_service.dart';
import '../../prayer_times/domain/entities/prayer_cache_status.dart';
import '../../prayer_times/domain/entities/prayer_location_diagnostic.dart';
import '../../prayer_times/domain/entities/ramadan_status.dart';
import '../../prayer_times/presentation/providers/ramadan_providers.dart';
import '../../prayer_times/services/adhan_manager.dart';
import '../../prayer_times/services/daily_inspiration_notification_service.dart';
import '../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../prayer_times/services/travel_mode_service.dart';
import '../../tracking/services/tracking_service.dart';
import 'adhan_selector_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SettingsService _settingsService = SettingsService.instance;

  bool adhanFajr = true;
  bool adhanDhuhr = true;
  bool adhanAsr = true;
  bool adhanMaghrib = true;
  bool adhanIsha = false;
  bool prayerNotificationsEnabled = true;
  bool haptics = true;
  bool autoLocation = true;
  bool travelerMode = true;
  bool ramadanAutomatic = true;
  bool ramadanForced = false;
  bool cloudBackupEnabled = false;
  bool cloudWifiOnly = true;
  int timeOffset = 0;
  bool isHanafi = false;
  CalculationMethod calculationMethod = CalculationMethod.muslim_world_league;

  // Hadices settings
  bool dailyInspirationEnabled = false;
  int dailyInspirationHour = 8;
  int hadithFavoritesCount = 0;

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
      travelerMode = prefs.getBool(AppConstants.keyTravelerModeEnabled) ?? true;
      ramadanAutomatic =
          prefs.getBool(AppConstants.keyRamadanModeAutomatic) ?? true;
      ramadanForced = prefs.getBool(AppConstants.keyRamadanModeForced) ?? false;
      cloudBackupEnabled = prefs.getBool(AppConstants.keyCloudBackupEnabled) ?? false;
      cloudWifiOnly = prefs.getBool(AppConstants.keyCloudWifiOnly) ?? true;
      timeOffset = prefs.getInt('time_offset') ?? 0;
      isHanafi = prefs.getBool('madhab_hanafi') ?? false;
      final methodIndex = prefs.getInt(AppConstants.keyCalculationMethod) ?? CalculationMethod.muslim_world_league.index;
      calculationMethod = CalculationMethod.values[methodIndex];
    });
    adhanFajr = await _settingsService.getPrayerNotificationEnabled('fajr');
    adhanDhuhr = await _settingsService.getPrayerNotificationEnabled('dhuhr');
    adhanAsr = await _settingsService.getPrayerNotificationEnabled('asr');
    adhanMaghrib = await _settingsService.getPrayerNotificationEnabled('maghrib');
    adhanIsha = await _settingsService.getPrayerNotificationEnabled('isha');
    prayerNotificationsEnabled = await _settingsService.getNotificationsEnabled();

    // Cargar configuración de hadices
    final inspirationService = ref.read(
      dailyInspirationNotificationServiceProvider,
    );
    dailyInspirationEnabled = await inspirationService.isEnabled();
    dailyInspirationHour = await inspirationService.getNotificationHour();
    hadithFavoritesCount =
        (await ref.read(hadithServiceProvider).getFavorites()).length;

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleBool(String key, bool value) async {
    await _settingsService.savePrayerNotificationEnabled(key, value);
    if (!mounted) return;
    setState(() {
      switch (key) {
        case 'fajr':
          adhanFajr = value;
          break;
        case 'dhuhr':
          adhanDhuhr = value;
          break;
        case 'asr':
          adhanAsr = value;
          break;
        case 'maghrib':
          adhanMaghrib = value;
          break;
        case 'isha':
          adhanIsha = value;
          break;
      }
    });
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
  }

  Future<void> _toggleCloudBackup(bool value) async {
    await ref.read(cloudSyncServiceProvider).setEnabled(value);
    if (!mounted) return;
    setState(() => cloudBackupEnabled = value);
  }

  Future<void> _toggleCloudWifiOnly(bool value) async {
    await ref.read(cloudSyncServiceProvider).setWifiOnly(value);
    if (!mounted) return;
    setState(() => cloudWifiOnly = value);
  }

  Future<void> _togglePrayerNotificationsEnabled(bool value) async {
    await ref.read(prayerNotificationsDataSourceProvider).setNotificationsEnabled(value);
    ref.invalidate(prayerNotificationsEnabledProvider);
    if (!mounted) return;
    setState(() => prayerNotificationsEnabled = value);
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
  }

  Future<void> _toggleRamadanAutomatic(bool value) async {
    await _settingsService.saveRamadanModeAutomatic(value);
    ref.invalidate(ramadanModeAutomaticProvider);
    ref.invalidate(ramadanStatusProvider);
    ref.invalidate(isRamadanProvider);
    if (!mounted) return;
    setState(() => ramadanAutomatic = value);
  }

  Future<void> _toggleRamadanForced(bool value) async {
    await _settingsService.saveRamadanModeForced(value);
    ref.invalidate(ramadanModeForcedProvider);
    ref.invalidate(ramadanStatusProvider);
    ref.invalidate(isRamadanProvider);
    if (!mounted) return;
    setState(() => ramadanForced = value);
  }

  // ── Funciones para Hadices ────────────────────────────────────────

  Future<void> _toggleDailyInspiration(bool value) async {
    final inspirationService = ref.read(
      dailyInspirationNotificationServiceProvider,
    );
    await inspirationService.initializeChannel();
    await inspirationService.setEnabled(value);
    if (!mounted) return;
    setState(() => dailyInspirationEnabled = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notificación diaria activada'
              : 'Notificación diaria desactivada',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectNotificationHour(QiblaTokens tokens) async {
    final hour = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.bgSurface,
        title: const Text('Seleccionar hora'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView(
            shrinkWrap: true,
            children: List.generate(
              24,
              (index) => ListTile(
                title: Text('${index}:00'),
                selected: index == dailyInspirationHour,
                onTap: () => Navigator.of(context).pop(index),
              ),
            ),
          ),
        ),
      ),
    );

    if (hour != null) {
      final inspirationService = ref.read(
        dailyInspirationNotificationServiceProvider,
      );
      await inspirationService.initializeChannel();
      await inspirationService.setNotificationHour(hour);
      if (!mounted) return;
      setState(() => dailyInspirationHour = hour);
    }
  }

  Future<void> _setTheme(String theme) async {
    await ref.read(themeControllerProvider.notifier).setTheme(theme);
  }

  Future<void> _setCalculationMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCalculationMethod, method.index);
    ref.invalidate(prayerCalculationMethodProvider);
    ref.invalidate(prayerScheduleProvider);
    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
    if (!mounted) return;
    setState(() => calculationMethod = method);
  }

  Future<void> _setMadhab(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('madhab_hanafi', value);
    ref.invalidate(prayerMadhabProvider);
    ref.invalidate(prayerScheduleProvider);
    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
    if (!mounted) return;
    setState(() => isHanafi = value);
  }

  Future<void> _updateOffset(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('time_offset', newValue);
    ref.invalidate(prayerTimeOffsetProvider);
    ref.invalidate(prayerScheduleProvider);
    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
    if (!mounted) return;
    setState(() => timeOffset = newValue);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final themeName = ref.watch(themeControllerProvider);
    final accessibility = ref.watch(accessibilityControllerProvider);
    final cacheStatus = ref.watch(prayerCacheStatusProvider);
    final lastBackup = ref.watch(_lastBackupProvider).valueOrNull;
    final deviceId = ref.watch(_deviceIdProvider).valueOrNull;
    final locationDiagnostic = ref.watch(prayerLocationDiagnosticProvider).valueOrNull;
    final locationLabel = ref.watch(lastLocationLabelProvider).valueOrNull;
    final notificationPermissionGranted =
        ref.watch(systemNotificationPermissionProvider).valueOrNull;
    final ramadanStatus = ref.watch(ramadanStatusProvider).valueOrNull;
    final prayerNotificationsStatus =
        ref.watch(prayerNotificationsEnabledProvider).valueOrNull ??
        prayerNotificationsEnabled;

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
                  Text('Tamaño de texto', style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary)),
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
              'Restablecer',
              onTap: () => ref.read(accessibilityControllerProvider.notifier).reset(),
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Notificaciones · adhan'),
            _buildValueTile(
              tokens,
              'Sonido del adhan',
              'Elegir y previsualizar',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdhanSelectorScreen()),
                );
              },
            ),
            _buildSimpleToggleTile(
              tokens,
              'Notificaciones generales',
              'Activa o pausa todos los avisos de oración',
              prayerNotificationsStatus,
              _togglePrayerNotificationsEnabled,
            ),
            if (notificationPermissionGranted == false)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_off_outlined, color: tokens.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los avisos de adhan están configurados, pero el permiso del sistema sigue pendiente.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          height: 1.5,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildToggleTile(tokens, 'Fajr', '6:12 · Adhan Al-Aqsa', adhanFajr, (v) => _toggleBool('fajr', v)),
            _buildToggleTile(tokens, 'Dhuhr', '13:45 · Adhan Makkah', adhanDhuhr, (v) => _toggleBool('dhuhr', v)),
            _buildToggleTile(tokens, 'Asr', '17:14 · Adhan Makkah', adhanAsr, (v) => _toggleBool('asr', v)),
            _buildToggleTile(tokens, 'Maghrib', '19:52 · Adhan Al-Aqsa', adhanMaghrib, (v) => _toggleBool('maghrib', v)),
            _buildToggleTile(tokens, 'Isha', '21:28 · Adhan Makkah', adhanIsha, (v) => _toggleBool('isha', v)),
            _buildSimpleToggleTile(tokens, 'Vibración háptica', 'En Tasbih y notificaciones', haptics, (v) => setState(() => haptics = v)),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Cálculo de horarios'),
            _buildValueTile(tokens, 'Método', calculationMethod.name.replaceAll('_', ' ').toUpperCase(), onTap: _showMethodSheet),
            _buildValueTile(tokens, 'Madhab (Asr)', isHanafi ? 'Hanafi' : 'Shafi\'i', onTap: () => _setMadhab(!isHanafi)),
            _buildValueTile(tokens, 'Ajuste manual', '±$timeOffset min', trailing: _offsetButtons(tokens)),
            _buildSimpleToggleTile(tokens, 'Ubicación', 'GPS automático', autoLocation, (v) => setState(() => autoLocation = v)),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Modo Ramadán'),
            _buildSimpleToggleTile(
              tokens,
              'Modo Ramadán automático',
              'Se activa solo cuando el calendario islámico entra en Ramadán',
              ramadanAutomatic,
              _toggleRamadanAutomatic,
            ),
            _buildSimpleToggleTile(
              tokens,
              'Forzar modo Ramadán',
              'Activar vista de Ramadán manualmente',
              ramadanForced,
              _toggleRamadanForced,
            ),
            if (ramadanStatus != null)
              _buildValueTile(
                tokens,
                'Estado actual',
                _ramadanStatusLabel(ramadanStatus),
              ),
            const SizedBox(height: 14),

            // ── SECCIÓN HADICES ────────────────────────────────────────
            _buildSectionTitle(tokens, 'Hadices'),
            _buildSimpleToggleTile(
              tokens,
              'Notificación diaria',
              'Recibe un hadiz o versículo cada día',
              dailyInspirationEnabled,
              (v) => _toggleDailyInspiration(v),
            ),
            _buildValueTile(
              tokens,
              'Hora de notificación',
              '${dailyInspirationHour}:00',
              onTap: () => _selectNotificationHour(tokens),
            ),
            const SizedBox(height: 14),

            // ── SECCIÓN TRAVEL MODE ────────────────────────────────────────
            _buildSectionTitle(tokens, 'Modo viajero'),

            // Toggle principal
            Consumer(
              builder: (context, ref, _) {
                final enabledAsync = ref.watch(travelerModeEnabledProvider);
                return enabledAsync.when(
                  data: (enabled) => _buildSimpleToggleTile(
                    tokens,
                    'Modo viajero',
                    'Detecta automáticamente cambios de ciudad (>50 km)',
                    enabled,
                    (value) async {
                      await ref.read(travelModeServiceProvider).setEnabled(value);
                      ref.invalidate(travelerModeEnabledProvider);
                    },
                  ),
                  loading: () => _buildSimpleToggleTile(tokens, 'Modo viajero', 'Cargando...', false, (_) {}),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 6),

            // Ubicaciones recientes
            Consumer(
              builder: (context, ref, _) {
                final locationsAsync = ref.watch(recentLocationsProvider);
                return locationsAsync.when(
                  data: (locations) {
                    if (locations.isEmpty) {
                      return _buildSettingRow(
                        label: 'Ubicaciones recientes',
                        subtitle: 'Sin viajes recientes',
                        trailing: Icon(Icons.history, color: tokens.textMuted, size: 18),
                        tokens: tokens,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                          child: Text(
                            'UBICACIONES RECIENTES',
                            style: TextStyle(
                              fontSize: 9,
                              color: tokens.textSecondary,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        ...locations.map((loc) => Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: tokens.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: tokens.primary, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.label,
                                      style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                                    ),
                                    Text(
                                      _formatDate(loc.timestamp),
                                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => _buildSettingRow(
                    label: 'Ubicaciones recientes',
                    subtitle: 'Error al cargar',
                    trailing: Icon(Icons.error, color: tokens.danger, size: 18),
                    tokens: tokens,
                  ),
                );
              },
            ),

            _buildSectionTitle(tokens, 'Caché inteligente'),
            _buildValueTile(tokens, 'Caché válida hasta', cacheStatus.validUntil?.toLocal().toString().substring(0, 16) ?? 'Sin caché'),
            _buildValueTile(tokens, 'Entradas en caché', '${cacheStatus.entryCount}'),
            _buildValueTile(
              tokens,
              'Limpiar caché',
              'Borrar',
              onTap: () async {
                await ref.read(prayerCacheDataSourceProvider).clear();
                ref.invalidate(prayerCacheStatusProvider);
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Estado del sistema'),
            _buildSystemStatusCard(
              tokens,
              locationLabel: locationLabel,
              locationDiagnostic: locationDiagnostic,
              notificationPermissionGranted: notificationPermissionGranted,
              prayerNotificationsStatus: prayerNotificationsStatus,
              cacheStatus: cacheStatus,
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
                        Text('Cada donación puede ser una sadaqah jariyah', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildValueTile(
              tokens,
              'Información de apoyo',
              'Abrir',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SupportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, 'Copia de seguridad en la nube (beta)'),
            _buildSimpleToggleTile(tokens, 'Copia automática', 'Prepara copias anónimas de tus datos', cloudBackupEnabled, _toggleCloudBackup),
            _buildSimpleToggleTile(tokens, 'Solo con Wi-Fi', 'Evita usar datos móviles en futuras sincronizaciones', cloudWifiOnly, _toggleCloudWifiOnly),
            _buildValueTile(tokens, 'ID anónimo', deviceId ?? 'Generando...'),
            _buildValueTile(tokens, 'Última copia', lastBackup == null ? 'Nunca' : lastBackup.toLocal().toString().substring(0, 16)),
            if (!cloudBackupEnabled && lastBackup == null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  'Todavía no has configurado copias de seguridad. Puedes exportar una primera copia manual cuando quieras.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.5,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            _buildValueTile(
              tokens,
              'Exportar copia',
              'Compartir',
              onTap: () async {
                final snapshot = await ref.read(cloudSyncServiceProvider).createBackupSnapshot(ref.read(hafizServiceProvider));
                if (!mounted) return;
                await Share.share(snapshot.toJsonString());
                ref.invalidate(_lastBackupProvider);
              },
            ),
            _buildValueTile(
              tokens,
              'Restaurar copia',
              'Importar JSON',
              onTap: _showRestoreDialog,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Text(
                'La base de la sincronización en la nube ya está lista. Cuando el backend quede definido, este mismo formato anónimo servirá para restaurar entre dispositivos.',
                style: GoogleFonts.dmSans(fontSize: 10, height: 1.6, color: tokens.textPrimary),
              ),
            ),
            _buildSectionTitle(tokens, 'Acerca de'),
            _buildValueTile(tokens, 'Versión', '3.0.0'),
            _buildValueTile(tokens, 'Licencias de código abierto', '→'),
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
                Text('Usuario', style: GoogleFonts.dmSans(fontSize: 15, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
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

  Widget _buildSystemStatusCard(
    QiblaTokens tokens, {
    required String? locationLabel,
    required PrayerLocationDiagnostic? locationDiagnostic,
    required bool? notificationPermissionGranted,
    required bool prayerNotificationsStatus,
    required PrayerCacheStatus cacheStatus,
  }) {
    final locationValue = locationLabel ??
        (locationDiagnostic?.lastKnownLocation == null
            ? 'Sin ubicación guardada'
            : '${locationDiagnostic!.lastKnownLocation!.latitude.toStringAsFixed(2)}, ${locationDiagnostic.lastKnownLocation!.longitude.toStringAsFixed(2)}');

    final locationStatus = switch (locationDiagnostic?.permissionStatus) {
      PrayerLocationPermissionStatus.deniedForever => 'Bloqueado',
      PrayerLocationPermissionStatus.denied => 'Pendiente',
      PrayerLocationPermissionStatus.granted => locationDiagnostic?.serviceEnabled == false ? 'GPS apagado' : 'Listo',
      _ => 'Sin comprobar',
    };

    final scheduleSource =
        cacheStatus.entryCount > 0 ? 'Caché preparada' : 'Pendiente';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          _diagnosticRow(tokens, 'Método', calculationMethod.name.replaceAll('_', ' ').toUpperCase()),
          _diagnosticRow(tokens, 'Madhab', isHanafi ? 'Hanafi' : 'Shafi\'i'),
          _diagnosticRow(tokens, 'Offset', '${timeOffset >= 0 ? '+' : ''}$timeOffset min'),
          _diagnosticRow(tokens, 'Notif. sistema', notificationPermissionGranted == null ? 'Comprobando...' : notificationPermissionGranted ? 'Concedidas' : 'Pendientes'),
          _diagnosticRow(tokens, 'Notif. app', prayerNotificationsStatus ? 'Activadas' : 'Pausadas'),
          _diagnosticRow(tokens, 'Ubicación', locationValue),
          _diagnosticRow(tokens, 'Estado de la ubicación', locationStatus),
          _diagnosticRow(tokens, 'Fuente horarios', scheduleSource),
          _diagnosticRow(tokens, 'Caché', '${cacheStatus.entryCount} entradas'),
        ],
      ),
    );
  }

  Widget _diagnosticRow(QiblaTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
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

  Future<void> _showRestoreDialog() async {
    final controller = TextEditingController();
    final tokens = QiblaThemes.current;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tokens.bgSurface,
          title: Text('Restaurar copia', style: GoogleFonts.dmSans(color: tokens.textPrimary, fontWeight: FontWeight.w600)),
          content: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 12,
            style: GoogleFonts.dmSans(color: tokens.textPrimary),
            decoration: const InputDecoration(hintText: 'Pega aquí el JSON exportado'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(cloudSyncServiceProvider).restoreFromJson(ref.read(hafizServiceProvider), controller.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                ref.invalidate(prayerScheduleProvider);
                ref.invalidate(prayerTrackingProvider);
                ref.invalidate(travelerModeEnabledProvider);
                ref.invalidate(themeControllerProvider);
                ref.invalidate(accessibilityControllerProvider);
                if (!mounted) return;
                _loadSettings();
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Copia restaurada')));
              },
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }

  // ── HELPERS PARA TRAVEL MODE ────────────────────────────────────

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _ramadanStatusLabel(RamadanStatus status) {
    if (status.isManualPreview) {
      return 'Activo manual';
    }
    if (status.isEnabled) {
      return status.headerLabel;
    }
    return 'Desactivado';
  }

  Widget _buildSettingRow({
    required String label,
    required String subtitle,
    required Widget trailing,
    required QiblaTokens tokens,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                Text(label, style: TextStyle(fontSize: 13, color: tokens.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

final _lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(cloudSyncServiceProvider).getLastBackup();
});

final _deviceIdProvider = FutureProvider<String>((ref) async {
  return ref.watch(cloudSyncServiceProvider).getDeviceId();
});
