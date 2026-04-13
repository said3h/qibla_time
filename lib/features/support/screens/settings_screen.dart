import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/country_catalog.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/adhan_model.dart';
import '../../../core/theme/accessibility_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/l10n.dart';
import '../../dhikr/services/dhikr_service.dart';
import '../../hafiz/services/hafiz_service.dart';
import '../../hadith/services/hadith_hourly_reminder_service.dart';
import '../../hadith/services/hadith_service.dart';
import '../../library/services/islamhouse_book_service.dart';
import '../../period/screens/period_guide_screen.dart';
import '../../period/services/period_mode_service.dart';
import '../../prayer_times/domain/entities/prayer_cache_status.dart';
import '../../prayer_times/domain/entities/prayer_location_diagnostic.dart';
import '../../prayer_times/domain/entities/prayer_name.dart';
import '../../prayer_times/domain/entities/ramadan_status.dart';
import '../../prayer_times/presentation/providers/ramadan_providers.dart';
import '../../prayer_times/services/adhan_manager.dart';
import '../../prayer_times/services/daily_inspiration_notification_service.dart';
import '../../prayer_times/services/notification_service.dart';
import '../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../prayer_times/services/quran_service.dart';
import '../../prayer_times/services/travel_mode_service.dart';
import '../../tracking/services/tracking_service.dart';
import '../../tracking/services/weekly_summary_notification_service.dart';
import '../services/dua_service.dart';
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
  bool travelerMode = true;
  bool ramadanAutomatic = true;
  bool ramadanForced = false;
  int timeOffset = 0;
  bool isHanafi = false;
  CalculationMethod calculationMethod = CalculationMethod.muslim_world_league;
  String selectedAdhanName = '';

  bool _exactAlarmPermissionGranted = true;

  // Hadices settings
  bool dailyInspirationEnabled = false;
  int dailyInspirationHour = 8;
  int hadithFavoritesCount = 0;
  String? _profileDisplayName;
  String? _profileNationalityCode;

  static const _languageOptions = <Locale?>[
    null,
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('id'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('ar'),
  ];

  static const _themes = [
    ('dark', '🌙'),
    ('light', '☀️'),
    ('amoled', '⚫'),
    ('deuteranopia', '👁'),
    ('monochrome', '⬜'),
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
    selectedAdhanName = _getAdhanName(await _settingsService.getAdhan());
    _profileDisplayName = await _settingsService.getProfileDisplayName();
    _profileNationalityCode =
        await _settingsService.getProfileNationalityCode();

    // Cargar configuración de hadices
    final inspirationService = ref.read(
      dailyInspirationNotificationServiceProvider,
    );
    dailyInspirationEnabled = await inspirationService.isEnabled();
    dailyInspirationHour = await inspirationService.getNotificationHour();
    hadithFavoritesCount =
        (await ref.read(hadithServiceProvider).getFavorites()).length;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        final status = await Permission.scheduleExactAlarm.status;
        if (mounted) setState(() => _exactAlarmPermissionGranted = status.isGranted);
      }
    }

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

  Future<void> _togglePeriodMode(bool value) async {
    await ref.read(periodModeServiceProvider).setEnabled(value);
    ref.invalidate(periodModeEnabledProvider);

    if (value) {
      await NotificationService.instance.cancelAll();
      return;
    }

    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
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
              ? context.l10n.settingsDailyNotificationEnabled
              : context.l10n.settingsDailyNotificationDisabled,
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
        title: Text(context.l10n.settingsSelectHourTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView(
            shrinkWrap: true,
            children: List.generate(
              24,
              (index) => ListTile(
                title: Text('$index:00'),
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

  Future<void> _openAdhanSelector() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdhanSelectorScreen()),
    );

    if (!mounted) return;
    await _loadSettings();
    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
  }

  Future<void> _setAppLocale(Locale? locale) async {
    await ref.read(appLocaleControllerProvider.notifier).setLocale(locale);
    ref.invalidate(dailyVerseProvider);
    ref.invalidate(dailyHadithProvider);
    ref.invalidate(allHadithsProvider);
    ref.invalidate(allDuasProvider);
    ref.invalidate(duaCategoriesProvider);
    ref.invalidate(islamHouseBooksProvider);
    ref.invalidate(islamHouseCategoriesProvider);
    ref.invalidate(islamHouseFeaturedBooksProvider);

    final dailyInspirationService =
        ref.read(dailyInspirationNotificationServiceProvider);
    final hadithReminderService =
        ref.read(hadithHourlyReminderServiceProvider);

    await ref.read(adhanManagerProvider).scheduleTodayAdhans();
    await dailyInspirationService.initializeChannel();
    await dailyInspirationService.scheduleDailyNotification();
    await hadithReminderService.initializeChannel();
    await hadithReminderService.scheduleAllReminders();
    await ref
        .read(weeklySummaryNotificationServiceProvider)
        .scheduleWeeklySummaryNotification();
  }

  Future<void> _showLanguageSheet() async {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final selectedLocale = ref.watch(appLocaleControllerProvider);
            final effectiveLocale = currentAppLocale(selectedLocale);

            return ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                Text(
                  l10n.settingsLanguageDialogTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ..._languageOptions.map((locale) {
                  final isSelected =
                      (selectedLocale?.languageCode ?? 'system') ==
                      (locale?.languageCode ?? 'system');
                  final title = locale == null
                      ? l10n.settingsLanguageOptionSystem
                      : _languageOptionTitle(locale.languageCode);
                  final subtitle = locale == null
                      ? l10n.settingsLanguageSystemValue(
                          _languageOptionTitle(effectiveLocale.languageCode),
                        )
                      : null;

                  return ListTile(
                    tileColor: isSelected ? tokens.activeBg : tokens.bgSurface2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(
                      title,
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? tokens.primaryLight
                            : tokens.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: tokens.textSecondary,
                            ),
                          ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: tokens.primary)
                        : null,
                    onTap: () async {
                      await _setAppLocale(locale);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
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
    final l10n = context.l10n;
    final appLocale = ref.watch(appLocaleControllerProvider);
    final effectiveAppLocale = currentAppLocale();
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
    final prayerSchedule = ref.watch(prayerScheduleProvider).valueOrNull?.schedule;
    final tracking = ref.watch(prayerTrackingProvider);
    final dhikrSnapshot = ref.watch(dhikrSnapshotProvider).valueOrNull;
    final prayerNotificationsStatus =
        ref.watch(prayerNotificationsEnabledProvider).valueOrNull ??
        prayerNotificationsEnabled;
    final profileDisplayName = _currentProfileDisplayName(l10n);
    final profileCountry = findCountryOption(_profileNationalityCode);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(l10n.settingsTitle, style: GoogleFonts.amiri(fontSize: 26, color: tokens.primary, fontWeight: FontWeight.bold)),
            Text(l10n.settingsTitleArabic, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
            const SizedBox(height: 16),
            _buildProfileCard(
              tokens,
              profileDisplayName: profileDisplayName,
              profileNationalityCode: _profileNationalityCode,
              profileNationalityName: profileCountry?.name,
              streakValue: tracking.hasAnyCompletedPrayer
                  ? '${tracking.currentStreak}'
                  : '—',
              prayersValue: tracking.hasAnyCompletedPrayer
                  ? '${tracking.totalPrayersCompleted}'
                  : '—',
              dhikrValue: dhikrSnapshot == null
                  ? '—'
                  : '${dhikrSnapshot.lifetimeTotal}',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(tokens, l10n.settingsSectionAppearance),
            ..._themes.map((theme) => _buildThemeTile(
                  tokens,
                  themeName,
                  theme.$1,
                  _themeTitle(theme.$1),
                  _themeSubtitle(theme.$1),
                  theme.$2,
                )),
            _buildSettingRow(
              label: l10n.settingsLanguage,
              subtitle: l10n.settingsLanguageSubtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _languageSettingValue(appLocale, effectiveAppLocale),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    color: tokens.textSecondary,
                    size: 18,
                  ),
                ],
              ),
              tokens: tokens,
              onTap: _showLanguageSheet,
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionAccessibility),
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
                  Text(l10n.settingsTextSize, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textPrimary)),
                  const SizedBox(height: 4),
                  Text(l10n.settingsCurrentScale(accessibility.fontScale.toStringAsFixed(1)), style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
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
            _buildSimpleToggleTile(tokens, l10n.settingsHighContrast, l10n.settingsHighContrastSubtitle, accessibility.highContrast, (v) => ref.read(accessibilityControllerProvider.notifier).setHighContrast(v)),
            _buildSimpleToggleTile(tokens, l10n.settingsUseSystemBold, l10n.settingsUseSystemBoldSubtitle, accessibility.useSystemBoldText, (v) => ref.read(accessibilityControllerProvider.notifier).setUseSystemBoldText(v)),
            _buildValueTile(
              tokens,
              l10n.settingsResetAccessibility,
              l10n.settingsReset,
              onTap: () => ref.read(accessibilityControllerProvider.notifier).reset(),
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionAdhanNotifications),
            _buildValueTile(
              tokens,
              l10n.settingsAdhanSound,
              l10n.settingsAdhanSoundAction,
              onTap: _openAdhanSelector,
            ),
            _buildSimpleToggleTile(
              tokens,
              l10n.settingsGeneralNotifications,
              l10n.settingsGeneralNotificationsSubtitle,
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
                        l10n.settingsSystemPermissionPendingBody,
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
            if (!_exactAlarmPermissionGranted && Platform.isAndroid)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_off, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El adhan puede no sonar si la app está cerrada. Activa las alarmas exactas en Ajustes.',
                        style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                        if (!mounted) return;
                        await _loadSettings();
                      },
                      child: const Text('Activar'),
                    ),
                  ],
                ),
              ),
            _buildToggleTile(tokens, _prayerSettingLabel('fajr', context), _buildPrayerSubtitle(prayerSchedule?.fajr), adhanFajr, (v) => _toggleBool('fajr', v)),
            _buildToggleTile(tokens, _prayerSettingLabel('dhuhr', context), _buildPrayerSubtitle(prayerSchedule?.dhuhr), adhanDhuhr, (v) => _toggleBool('dhuhr', v)),
            _buildToggleTile(tokens, _prayerSettingLabel('asr', context), _buildPrayerSubtitle(prayerSchedule?.asr), adhanAsr, (v) => _toggleBool('asr', v)),
            _buildToggleTile(tokens, _prayerSettingLabel('maghrib', context), _buildPrayerSubtitle(prayerSchedule?.maghrib), adhanMaghrib, (v) => _toggleBool('maghrib', v)),
            _buildToggleTile(tokens, _prayerSettingLabel('isha', context), _buildPrayerSubtitle(prayerSchedule?.isha), adhanIsha, (v) => _toggleBool('isha', v)),
            _buildValueTile(
              tokens,
              l10n.settingsHapticFeedback,
              l10n.commonUnavailable,
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionPeriodMode),
            Consumer(
              builder: (context, ref, _) {
                final enabledAsync = ref.watch(periodModeEnabledProvider);
                return enabledAsync.when(
                  data: (enabled) => _buildSimpleToggleTile(
                    tokens,
                    l10n.settingsPeriodMode,
                    l10n.settingsPeriodModeSubtitle,
                    enabled,
                    _togglePeriodMode,
                  ),
                  loading: () => _buildSimpleToggleTile(
                    tokens,
                    l10n.settingsPeriodMode,
                    l10n.commonLoading,
                    false,
                    (_) {},
                  ),
                  error: (_, __) => _buildSettingRow(
                    label: l10n.settingsPeriodMode,
                    subtitle: l10n.settingsLoadError,
                    trailing: Icon(
                      Icons.info_outline,
                      color: tokens.textMuted,
                      size: 18,
                    ),
                    tokens: tokens,
                  ),
                );
              },
            ),
            _buildValueTile(
              tokens,
              l10n.periodGuideTitle,
              l10n.commonOpen,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PeriodGuideScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionScheduleCalculation),
            _buildValueTile(tokens, l10n.commonMethod, calculationMethod.name.replaceAll('_', ' ').toUpperCase(), onTap: _showMethodSheet),
            _buildValueTile(tokens, l10n.settingsMadhabAsr, isHanafi ? l10n.onboardingMadhabHanafiTitle : l10n.commonShafii, onTap: () => _setMadhab(!isHanafi)),
            _buildValueTile(tokens, l10n.settingsManualAdjustment, '+/-$timeOffset min', trailing: _offsetButtons(tokens)),
            _buildValueTile(
              tokens,
              l10n.commonLocation,
              _locationSettingValue(locationDiagnostic),
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionRamadanMode),
            _buildSimpleToggleTile(
              tokens,
              l10n.settingsRamadanAutomatic,
              l10n.settingsRamadanAutomaticSubtitle,
              ramadanAutomatic,
              _toggleRamadanAutomatic,
            ),
            _buildSimpleToggleTile(
              tokens,
              l10n.settingsRamadanForced,
              l10n.settingsRamadanForcedSubtitle,
              ramadanForced,
              _toggleRamadanForced,
            ),
            if (ramadanStatus != null)
              _buildValueTile(
                tokens,
                l10n.commonCurrentStatus,
                _ramadanStatusLabel(ramadanStatus),
              ),
            const SizedBox(height: 14),

            // ── SECCIÓN HADICES ────────────────────────────────────────
            _buildSectionTitle(tokens, l10n.settingsSectionHadith),
            _buildSimpleToggleTile(
              tokens,
              l10n.settingsDailyNotification,
              l10n.settingsDailyNotificationSubtitle,
              dailyInspirationEnabled,
              (v) => _toggleDailyInspiration(v),
            ),
            _buildValueTile(
              tokens,
              l10n.settingsNotificationHour,
              '$dailyInspirationHour:00',
              onTap: () => _selectNotificationHour(tokens),
            ),
            const SizedBox(height: 14),

            // ── SECCIÓN TRAVEL MODE ────────────────────────────────────────
            _buildSectionTitle(tokens, l10n.settingsSectionTravelerMode),

            // Toggle principal
            Consumer(
              builder: (context, ref, _) {
                final enabledAsync = ref.watch(travelerModeEnabledProvider);
                return enabledAsync.when(
                  data: (enabled) => _buildSimpleToggleTile(
                    tokens,
                    l10n.settingsTravelerMode,
                    l10n.settingsTravelerModeSubtitle,
                    enabled,
                    (value) async {
                      await ref.read(travelModeServiceProvider).setEnabled(value);
                      ref.invalidate(travelerModeEnabledProvider);
                    },
                  ),
                  loading: () => _buildSimpleToggleTile(tokens, l10n.settingsTravelerMode, l10n.commonLoading, false, (_) {}),
                  error: (_, __) => _buildSettingRow(
                    label: l10n.settingsTravelerMode,
                    subtitle: l10n.settingsTravelerModeLoadError,
                    trailing: Icon(
                      Icons.info_outline,
                      color: tokens.textMuted,
                      size: 18,
                    ),
                    tokens: tokens,
                  ),
                );
              },
            ),

            const SizedBox(height: 6),

            // Lugares recientes
            Consumer(
              builder: (context, ref, _) {
                final locationsAsync = ref.watch(recentLocationsProvider);
                return locationsAsync.when(
                  data: (locations) {
                    if (locations.isEmpty) {
                      return _buildSettingRow(
                        label: l10n.settingsRecentPlaces,
                        subtitle: l10n.settingsNoRecentTrips,
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
                            l10n.settingsSectionRecentPlaces,
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
                    label: l10n.settingsRecentPlaces,
                    subtitle: l10n.settingsLoadError,
                    trailing: Icon(Icons.error, color: tokens.danger, size: 18),
                    tokens: tokens,
                  ),
                );
              },
            ),

            _buildSectionTitle(tokens, l10n.settingsSectionSmartCache),
            _buildValueTile(tokens, l10n.settingsCacheValidUntil, cacheStatus.validUntil?.toLocal().toString().substring(0, 16) ?? l10n.commonUnavailable),
            _buildValueTile(tokens, l10n.settingsCacheEntries, '${cacheStatus.entryCount}'),
            _buildValueTile(
              tokens,
              l10n.settingsClearCache,
              l10n.commonDelete,
              onTap: () async {
                await ref.read(prayerCacheDataSourceProvider).clear();
                ref.invalidate(prayerCacheStatusProvider);
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.commonSystemStatus),
            _buildSystemStatusCard(
              tokens,
              locationLabel: locationLabel,
              locationDiagnostic: locationDiagnostic,
              notificationPermissionGranted: notificationPermissionGranted,
              prayerNotificationsStatus: prayerNotificationsStatus,
              cacheStatus: cacheStatus,
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionSupport),
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
                  Icon(Icons.favorite_rounded, color: tokens.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.settingsSupportCardTitle, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.primaryLight, fontWeight: FontWeight.w500)),
                        Text(l10n.settingsSupportCardSubtitle, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildValueTile(
              tokens,
              l10n.settingsSupportInfo,
              l10n.commonOpen,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SupportScreen(),
                  ),
                );
              },
            ),
            _buildValueTile(
              tokens,
              l10n.rateApp,
              l10n.commonOpen,
              trailing: Icon(Icons.star_rounded, size: 16, color: tokens.primary),
              onTap: () async {
                final uri = Uri.parse('market://details?id=com.qiblatime.qibla_time');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  final fallback = Uri.parse('https://play.google.com/store/apps/details?id=com.qiblatime.qibla_time');
                  await launchUrl(fallback, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 14),
            _buildSectionTitle(tokens, l10n.settingsSectionCloudBackup),
            _buildValueTile(tokens, l10n.settingsBackupMode, l10n.commonManual),
            _buildValueTile(tokens, l10n.settingsAnonymousId, deviceId ?? l10n.commonGenerating),
            _buildValueTile(tokens, l10n.settingsLastBackup, lastBackup == null ? l10n.commonNever : lastBackup.toLocal().toString().substring(0, 16)),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                l10n.settingsBackupInfoBody,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  height: 1.5,
                  color: tokens.textSecondary,
                ),
              ),
            ),
            _buildValueTile(
              tokens,
              l10n.settingsExportBackup,
              l10n.commonShare,
              onTap: () async {
                final snapshot = await ref.read(cloudSyncServiceProvider).createBackupSnapshot(ref.read(hafizServiceProvider));
                if (!mounted) return;
                await Share.share(snapshot.toJsonString());
                ref.invalidate(_lastBackupProvider);
              },
            ),
            _buildValueTile(
              tokens,
              l10n.settingsRestoreBackup,
              l10n.commonImportJson,
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
                l10n.settingsBackupInfoBody,
                style: GoogleFonts.dmSans(fontSize: 10, height: 1.6, color: tokens.textPrimary),
              ),
            ),
            _buildSectionTitle(tokens, l10n.commonAbout),
            _buildValueTile(tokens, l10n.commonVersion, '3.0.0'),
            _buildValueTile(tokens, l10n.settingsOpenSourceLicenses, '→'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    QiblaTokens tokens, {
    required String profileDisplayName,
    required String? profileNationalityCode,
    required String? profileNationalityName,
    required String streakValue,
    required String prayersValue,
    required String dhikrValue,
  }) {
    final l10n = context.l10n;
    final flag = countryFlagEmoji(profileNationalityCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _showProfileEditorSheet,
        child: Container(
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
                child: Center(
                  child: Text(
                    profileDisplayName.trim().isEmpty
                        ? 'U'
                        : profileDisplayName.trim().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: tokens.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (flag.isNotEmpty) ...[
                          Text(flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            profileDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profileNationalityName ??
                          l10n.settingsProfileEditSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat(tokens, streakValue, l10n.settingsProfileStreak),
                        const SizedBox(width: 12),
                        _stat(tokens, prayersValue, l10n.settingsProfilePrayers),
                        const SizedBox(width: 12),
                        _stat(tokens, dhikrValue, l10n.settingsProfileTasbih),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  String _currentProfileDisplayName(AppLocalizations l10n) {
    final name = _profileDisplayName?.trim();
    if (name == null || name.isEmpty) {
      return l10n.settingsProfileUser;
    }
    return name;
  }

  Future<void> _showProfileEditorSheet() async {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final nameController = TextEditingController(text: _profileDisplayName ?? '');
    String? selectedCountryCode = _profileNationalityCode;

    final result = await showModalBottomSheet<_ProfileDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCountry = findCountryOption(selectedCountryCode);
            final flag = countryFlagEmoji(selectedCountryCode);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsProfileEditTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsProfileEditSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.settingsProfileNameLabel,
                      hintText: l10n.settingsProfileNameHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: tokens.bgSurface2,
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: flag.isEmpty
                          ? Icon(
                              Icons.public,
                              color: tokens.textSecondary,
                            )
                          : Text(
                              flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                    ),
                    title: Text(
                      l10n.settingsProfileNationalityLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      selectedCountry?.name ??
                          l10n.settingsProfileNationalityNone,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final pickedCountryCode = await _showCountryPickerSheet(
                        initialCountryCode: selectedCountryCode,
                      );
                      if (pickedCountryCode == null) {
                        return;
                      }
                      setModalState(() {
                        selectedCountryCode = pickedCountryCode.isEmpty
                            ? null
                            : pickedCountryCode;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _ProfileDraft(
                                displayName: nameController.text.trim(),
                                nationalityCode: selectedCountryCode,
                              ),
                            );
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == null) {
      return;
    }

    final normalizedName = result.displayName.trim();
    await _settingsService.saveProfileDisplayName(
      normalizedName.isEmpty ? null : normalizedName,
    );
    await _settingsService.saveProfileNationalityCode(result.nationalityCode);

    if (!mounted) {
      return;
    }

    setState(() {
      _profileDisplayName = normalizedName.isEmpty ? null : normalizedName;
      _profileNationalityCode = result.nationalityCode;
    });
  }

  Future<String?> _showCountryPickerSheet({
    required String? initialCountryCode,
  }) async {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final searchController = TextEditingController();
    String query = '';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCountries = countryCatalog.where((country) {
              if (query.isEmpty) {
                return true;
              }
              final normalizedQuery = query.toLowerCase();
              return country.name.toLowerCase().contains(normalizedQuery) ||
                  country.code.toLowerCase().contains(normalizedQuery);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: SizedBox(
                height: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsProfileChooseCountry,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: l10n.settingsProfileCountrySearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setModalState(() => query = value.trim());
                      },
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.public,
                              color: tokens.textSecondary,
                            ),
                            title: Text(l10n.settingsProfileNationalityNone),
                            trailing: initialCountryCode == null
                                ? Icon(Icons.check, color: tokens.primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(''),
                          ),
                          ...filteredCountries.map((country) {
                            final isSelected =
                                country.code == initialCountryCode;
                            return ListTile(
                              leading: Text(
                                countryFlagEmoji(country.code),
                                style: const TextStyle(fontSize: 20),
                              ),
                              title: Text(country.name),
                              subtitle: Text(country.code),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: tokens.primary)
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pop(country.code),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  String _getAdhanName(String file) {
    final adhan = AdhanModel.availableAdhans.firstWhere(
      (item) => item.file == file,
      orElse: () => AdhanModel(name: 'Adhan', file: file),
    );
    return adhan.name;
  }

  String _buildPrayerSubtitle(DateTime? time) {
    final timeLabel = time == null ? context.l10n.commonUnavailable : _formatTime(time);
    return '$timeLabel | $selectedAdhanName';
  }

  String _prayerSettingLabel(String prayerKey, BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return switch (prayerKey) {
      'fajr' => PrayerName.fajr.localizedDisplayName(languageCode),
      'dhuhr' => PrayerName.dhuhr.localizedDisplayName(languageCode),
      'asr' => PrayerName.asr.localizedDisplayName(languageCode),
      'maghrib' => PrayerName.maghrib.localizedDisplayName(languageCode),
      'isha' => PrayerName.isha.localizedDisplayName(languageCode),
      _ => prayerKey,
    };
  }

  String _themeTitle(String id) {
    final l10n = context.l10n;
    return switch (id) {
      'dark' => l10n.settingsThemeDarkTitle,
      'light' => l10n.settingsThemeLightTitle,
      'amoled' => l10n.settingsThemeAmoledTitle,
      'deuteranopia' => l10n.settingsThemeDeuteranopiaTitle,
      'monochrome' => l10n.settingsThemeMonochromeTitle,
      _ => id,
    };
  }

  String _themeSubtitle(String id) {
    final l10n = context.l10n;
    return switch (id) {
      'dark' => l10n.settingsThemeDarkSubtitle,
      'light' => l10n.settingsThemeLightSubtitle,
      'amoled' => l10n.settingsThemeAmoledSubtitle,
      'deuteranopia' => l10n.settingsThemeDeuteranopiaSubtitle,
      'monochrome' => l10n.settingsThemeMonochromeSubtitle,
      _ => '',
    };
  }

  String _languageSettingValue(Locale? appLocale, Locale effectiveLocale) {
    final l10n = context.l10n;
    if (appLocale == null) {
      return l10n.settingsLanguageSystemValue(
        _languageOptionTitle(effectiveLocale.languageCode),
      );
    }

    return _languageOptionTitle(appLocale.languageCode);
  }

  String _languageOptionTitle(String languageCode) {
    final l10n = context.l10n;
    return switch (languageCode) {
      'es' => l10n.settingsLanguageOptionSpanish,
      'en' => l10n.settingsLanguageOptionEnglish,
      'fr' => l10n.settingsLanguageOptionFrench,
      'de' => l10n.settingsLanguageOptionGerman,
      'it' => l10n.settingsLanguageOptionItalian,
      'id' => l10n.settingsLanguageOptionIndonesian,
      'nl' => l10n.settingsLanguageOptionDutch,
      'pt' => l10n.settingsLanguageOptionPortuguese,
      'ru' => l10n.settingsLanguageOptionRussian,
      'ar' => l10n.settingsLanguageOptionArabic,
      _ => languageCode.toUpperCase(),
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
            activeThumbColor: tokens.bgPage,
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
    final l10n = context.l10n;
    final locationValue = locationLabel ??
        (locationDiagnostic?.lastKnownLocation == null
            ? l10n.settingsLocationSavedUnavailable
            : '${locationDiagnostic!.lastKnownLocation!.latitude.toStringAsFixed(2)}, ${locationDiagnostic.lastKnownLocation!.longitude.toStringAsFixed(2)}');

    final locationStatus = switch (locationDiagnostic?.permissionStatus) {
      PrayerLocationPermissionStatus.deniedForever => l10n.commonBlocked,
      PrayerLocationPermissionStatus.denied => l10n.commonPending,
      PrayerLocationPermissionStatus.granted => locationDiagnostic?.serviceEnabled == false ? l10n.settingsGpsOff : l10n.commonReady,
      _ => l10n.commonChecking,
    };

    final scheduleSource =
        cacheStatus.entryCount > 0 ? l10n.settingsScheduleSourceReady : l10n.commonPending;

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
          _diagnosticRow(tokens, l10n.commonMethod, calculationMethod.name.replaceAll('_', ' ').toUpperCase()),
          _diagnosticRow(tokens, l10n.commonMadhab, isHanafi ? l10n.onboardingMadhabHanafiTitle : l10n.commonShafii),
          _diagnosticRow(tokens, l10n.commonOffset, '${timeOffset >= 0 ? '+' : ''}$timeOffset min'),
          _diagnosticRow(tokens, l10n.settingsNotificationSystem, notificationPermissionGranted == null ? l10n.commonChecking : notificationPermissionGranted ? l10n.settingsNotificationsGranted : l10n.commonPending),
          _diagnosticRow(tokens, l10n.settingsNotificationApp, prayerNotificationsStatus ? l10n.commonActivated : l10n.commonPaused),
          _diagnosticRow(tokens, l10n.commonLocation, locationValue),
          _diagnosticRow(tokens, l10n.settingsLocationStatus, locationStatus),
          _diagnosticRow(tokens, l10n.settingsScheduleSource, scheduleSource),
          _diagnosticRow(tokens, l10n.settingsCacheEntries, '${cacheStatus.entryCount}'),
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
        Text('+/-$timeOffset', style: GoogleFonts.dmSans(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w500)),
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
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tokens.bgSurface,
          title: Text(l10n.settingsRestoreBackupDialogTitle, style: GoogleFonts.dmSans(color: tokens.textPrimary, fontWeight: FontWeight.w600)),
          content: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 12,
            style: GoogleFonts.dmSans(color: tokens.textPrimary),
            decoration: InputDecoration(hintText: l10n.settingsRestoreBackupPasteHint),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(cloudSyncServiceProvider).restoreFromJson(
                    ref.read(hafizServiceProvider),
                    controller.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ref.invalidate(prayerScheduleProvider);
                  ref.invalidate(prayerTrackingProvider);
                  ref.invalidate(travelerModeEnabledProvider);
                  ref.invalidate(themeControllerProvider);
                  ref.invalidate(accessibilityControllerProvider);
                  if (!mounted) return;
                  _loadSettings();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsRestoreBackupSuccess)),
                  );
                } on CloudSyncRestoreException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsRestoreBackupError)),
                  );
                }
              },
              child: Text(l10n.commonRestore),
            ),
          ],
        );
      },
    );
  }

  // ── HELPERS PARA TRAVEL MODE ────────────────────────────────────

  String _formatDate(DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return l10n.settingsToday;
    if (diff.inDays == 1) return l10n.settingsYesterday;
    if (diff.inDays < 7) return l10n.settingsDaysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _ramadanStatusLabel(RamadanStatus status) {
    final l10n = context.l10n;
    if (status.isManualPreview) {
      return l10n.settingsRamadanManualActive;
    }
    if (status.isEnabled) {
      return status.headerLabel;
    }
    return l10n.commonDisabled;
  }

  String _locationSettingValue(PrayerLocationDiagnostic? diagnostic) {
    final l10n = context.l10n;
    return switch (diagnostic?.permissionStatus) {
      PrayerLocationPermissionStatus.granted =>
        diagnostic?.serviceEnabled == false ? l10n.settingsGpsOff : l10n.settingsLocationAutomatic,
      PrayerLocationPermissionStatus.denied => l10n.settingsLocationPendingPermission,
      PrayerLocationPermissionStatus.deniedForever => l10n.settingsLocationBlocked,
      _ => l10n.commonUnavailable,
    };
  }

  Widget _buildSettingRow({
    required String label,
    required String subtitle,
    required Widget trailing,
    required QiblaTokens tokens,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({
    required this.displayName,
    required this.nationalityCode,
  });

  final String displayName;
  final String? nationalityCode;
}

final _lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(cloudSyncServiceProvider).getLastBackup();
});

final _deviceIdProvider = FutureProvider<String>((ref) async {
  return ref.watch(cloudSyncServiceProvider).getDeviceId();
});
