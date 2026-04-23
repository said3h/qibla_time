import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../prayer_times/services/adhan_manager.dart';
import '../../prayer_times/services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    required this.onSkipped,
  });

  final Future<void> Function() onCompleted;
  final Future<void> Function() onSkipped;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const int _pageCount = 6;

  final PageController _controller = PageController();
  final SettingsService _settingsService = SettingsService.instance;
  final AudioService _audioService = AudioService.instance;

  int _step = 0;
  bool _busy = false;
  bool _notificationsEnabled = true;
  bool _playingPreview = false;
  CalculationMethod _method = CalculationMethod.muslim_world_league;
  bool _isHanafi = false;
  LocationPermission _locationPermission = LocationPermission.unableToDetermine;
  bool _locationServiceEnabled = false;
  bool _notificationsGranted = false;
  bool _didTriggerInitialSchedule = false;

  static const _recommendedMethods = [
    CalculationMethod.muslim_world_league,
    CalculationMethod.north_america,
    CalculationMethod.umm_al_qura,
    CalculationMethod.egyptian,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    _refreshPermissionState(clearBusy: true);
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt('calculation_method');
    final hanafi = prefs.getBool('madhab_hanafi') ?? false;
    final notifEnabled = await _settingsService.getNotificationsEnabled();
    final permissionState = await _readPermissionState();

    if (!mounted) return;
    setState(() {
      _method = methodIndex == null
          ? CalculationMethod.muslim_world_league
          : CalculationMethod.values[methodIndex];
      _isHanafi = hanafi;
      _notificationsEnabled = notifEnabled;
      _locationPermission = permissionState.locationPermission;
      _locationServiceEnabled = permissionState.locationServiceEnabled;
      _notificationsGranted = permissionState.notificationsGranted;
    });
  }

  Future<
      ({
        LocationPermission locationPermission,
        bool locationServiceEnabled,
        bool notificationsGranted,
      })> _readPermissionState() async {
    final locationPermission = await Geolocator.checkPermission();
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    final notificationsGranted =
        await NotificationService.instance.areNotificationsEnabled();

    return (
      locationPermission: locationPermission,
      locationServiceEnabled: locationServiceEnabled,
      notificationsGranted: notificationsGranted,
    );
  }

  Future<void> _refreshPermissionState({bool clearBusy = false}) async {
    try {
      final permissionState = await _readPermissionState();
      if (!mounted) return;
      setState(() {
        _locationPermission = permissionState.locationPermission;
        _locationServiceEnabled = permissionState.locationServiceEnabled;
        _notificationsGranted = permissionState.notificationsGranted;
        if (clearBusy) {
          _busy = false;
        }
      });
      _maybeTriggerAdhanScheduling('refreshPermissionState');
    } catch (_) {
      if (!mounted || !clearBusy) return;
      setState(() => _busy = false);
    }
  }

  bool get _hasLocationPermission =>
      _locationPermission == LocationPermission.always ||
      _locationPermission == LocationPermission.whileInUse;

  void _maybeTriggerAdhanScheduling(String reason) {
    if (!mounted || _didTriggerInitialSchedule) return;
    if (!_hasLocationPermission || !_locationServiceEnabled) return;

    // On clean installs, the first schedule attempt (startup) may run before
    // permissions/services are ready and abort in AdhanManager. Once onboarding
    // grants location and services are enabled, trigger a single background
    // re-attempt so release users actually get notifications scheduled.
    _didTriggerInitialSchedule = true;
    AppLogger.info('Onboarding._maybeTriggerAdhanScheduling: triggering scheduleTodayAdhans reason=$reason');

    Future<void>(() async {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        await container.read(adhanManagerProvider).scheduleTodayAdhans();
        AppLogger.info('Onboarding._maybeTriggerAdhanScheduling: scheduleTodayAdhans OK reason=$reason');
      } catch (e, st) {
        AppLogger.error(
          'Onboarding._maybeTriggerAdhanScheduling: scheduleTodayAdhans FAILED reason=$reason',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _next() async {
    if (_step >= _pageCount - 1) return;
    await _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _requestLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.denied) {
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
      }
    } finally {
      await _refreshPermissionState(clearBusy: true);
      _maybeTriggerAdhanScheduling('requestLocation');
    }
  }

  Future<void> _requestNotifications() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _settingsService.saveNotificationsEnabled(true);
      final granted = await NotificationService.instance.requestPermission();
      if (!mounted) return;
      setState(() {
        _notificationsGranted = granted;
        _notificationsEnabled = true;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _persistMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calculation_method', method.index);
    if (!mounted) return;
    setState(() => _method = method);
  }

  Future<void> _persistMadhab(bool isHanafi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('madhab_hanafi', isHanafi);
    if (!mounted) return;
    setState(() => _isHanafi = isHanafi);
  }

  Future<void> _toggleNotifications(bool value) async {
    await _settingsService.saveNotificationsEnabled(value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _togglePreview() async {
    if (_playingPreview) {
      await _audioService.stop();
      if (!mounted) return;
      setState(() => _playingPreview = false);
      return;
    }

    await _audioService.playAdhan(await _settingsService.getAdhan());
    if (!mounted) return;
    setState(() => _playingPreview = true);
    _audioService.onPlayerComplete.first.then((_) {
      if (mounted) {
        setState(() => _playingPreview = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    final isLastStep = _step == _pageCount - 1;
    final primaryActionLabel =
        isLastStep ? l10n.commonEnter : l10n.commonNext;
    final primaryAction = isLastStep ? widget.onCompleted : _next;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _pageCount,
                        minHeight: 6,
                        color: tokens.primary,
                        backgroundColor: tokens.bgSurface2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _busy ? null : () => widget.onSkipped(),
                    child: Text(l10n.commonSkip),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _step = value),
                  children: [
                    _buildWelcome(tokens, isArabicOnly),
                    _buildPermissions(tokens, isArabicOnly),
                    _buildMethod(tokens, isArabicOnly),
                    _buildMadhab(tokens, isArabicOnly),
                    _buildAdhan(tokens, isArabicOnly),
                    _buildDone(tokens, isArabicOnly),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_step != 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _back,
                        child: Text(l10n.commonBack),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : primaryAction,
                      child: Text(primaryActionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildIntro(QiblaTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: tokens.primaryBorder, width: 1.5),
                ),
                child: Icon(
                  Icons.nights_stay_rounded,
                  color: tokens.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Qibla Time',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'وقت القبلة',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _FeatureCard(
          icon: Icons.block_rounded,
          title: l10n.onboardingIntroNoAds,
          body: l10n.onboardingIntroNoAdsBody,
          tokens: tokens,
          isArabicOnly: false,
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          icon: Icons.shield_outlined,
          title: l10n.onboardingIntroPrivacy,
          body: l10n.onboardingIntroPrivacyBody,
          tokens: tokens,
          isArabicOnly: false,
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          icon: Icons.language_rounded,
          title: l10n.onboardingIntroLanguages,
          body: l10n.onboardingIntroLanguagesBody,
          tokens: tokens,
          isArabicOnly: false,
        ),
      ],
    );
  }

  Widget _buildWelcome(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    return _StepScaffold(
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeSubtitle,
      isArabicOnly: isArabicOnly,
      child: Column(
        children: [
          _FeatureCard(
            icon: Icons.access_time_rounded,
            title: l10n.onboardingFeatureSchedulesTitle,
            body: l10n.onboardingFeatureSchedulesBody,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            icon: Icons.explore_rounded,
            title: l10n.onboardingFeaturePracticeTitle,
            body: l10n.onboardingFeaturePracticeBody,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            icon: Icons.notifications_active_outlined,
            title: l10n.onboardingFeatureRemindersTitle,
            body: l10n.onboardingFeatureRemindersBody,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    final locationReady = _locationServiceEnabled && _hasLocationPermission;
    final locationActionLabel = _locationPermission ==
            LocationPermission.deniedForever
        ? l10n.commonOpenSettings
        : _hasLocationPermission && !_locationServiceEnabled
            ? l10n.commonEnableGps
            : l10n.commonAllow;
    final locationStatus = locationReady
        ? l10n.commonGranted
        : _locationPermission == LocationPermission.deniedForever
            ? l10n.commonBlocked
            : _hasLocationPermission && !_locationServiceEnabled
                ? l10n.settingsGpsOff
                : l10n.commonPending;

    return _StepScaffold(
      title: l10n.onboardingPermissionsTitle,
      subtitle: l10n.onboardingPermissionsSubtitle,
      isArabicOnly: isArabicOnly,
      child: Column(
        children: [
          _PermissionCard(
            icon: Icons.place_outlined,
            title: l10n.commonLocation,
            body: locationReady
                ? l10n.onboardingLocationReadyBody
                : _locationPermission == LocationPermission.deniedForever
                    ? l10n.onboardingLocationBlockedBody
                    : _hasLocationPermission && !_locationServiceEnabled
                        ? l10n.onboardingLocationGpsOffBody
                        : l10n.onboardingLocationPendingBody,
            status: locationStatus,
            actionLabel: locationActionLabel,
            action: _requestLocation,
            tokens: tokens,
            completed: locationReady,
            loading: _busy,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            icon: Icons.notifications_none_rounded,
            title: l10n.commonNotifications,
            body: _notificationsGranted
                ? l10n.onboardingNotificationsReadyBody
                : l10n.onboardingNotificationsPendingBody,
            status: _notificationsGranted
                ? l10n.commonGranted
                : l10n.commonPending,
            actionLabel: l10n.commonActivate,
            action: _requestNotifications,
            tokens: tokens,
            completed: _notificationsGranted,
            loading: _busy,
            isArabicOnly: isArabicOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildMethod(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    return _StepScaffold(
      title: l10n.onboardingMethodTitle,
      subtitle: l10n.onboardingMethodSubtitle,
      isArabicOnly: isArabicOnly,
      child: Column(
        children: _recommendedMethods.map((method) {
          final selected = method == _method;
          return _SelectableTile(
            title: _methodLabel(method),
            subtitle: selected
                ? l10n.onboardingSelectedNow
                : l10n.onboardingTapToChooseMethod,
            selected: selected,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
            onTap: () => _persistMethod(method),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMadhab(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    return _StepScaffold(
      title: l10n.onboardingMadhabTitle,
      subtitle: l10n.onboardingMadhabSubtitle,
      isArabicOnly: isArabicOnly,
      child: Column(
        children: [
          _SelectableTile(
            title: l10n.onboardingMadhabCommonTitle,
            subtitle: l10n.onboardingMadhabCommonSubtitle,
            selected: !_isHanafi,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
            onTap: () => _persistMadhab(false),
          ),
          _SelectableTile(
            title: l10n.onboardingMadhabHanafiTitle,
            subtitle: l10n.onboardingMadhabHanafiSubtitle,
            selected: _isHanafi,
            tokens: tokens,
            isArabicOnly: isArabicOnly,
            onTap: () => _persistMadhab(true),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhan(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    return _StepScaffold(
      title: l10n.onboardingAdhanTitle,
      subtitle: l10n.onboardingAdhanSubtitle,
      isArabicOnly: isArabicOnly,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: isArabicOnly
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingPrayerNotificationsTitle,
                        textAlign:
                            isArabicOnly ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.onboardingPrayerNotificationsSubtitle,
                        textAlign:
                            isArabicOnly ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: tokens.bgPage,
                  activeTrackColor: tokens.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: isArabicOnly
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingAdhanPreviewTitle,
                  textAlign:
                      isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.onboardingAdhanPreviewSubtitle,
                  textAlign:
                      isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _togglePreview,
                  icon: Icon(_playingPreview ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  label: Text(
                    _playingPreview
                        ? l10n.onboardingAdhanStopPreview
                        : l10n.onboardingAdhanListenPreview,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = context.l10n;
    return _StepScaffold(
      title: l10n.onboardingDoneTitle,
      subtitle: l10n.onboardingDoneSubtitle,
      isArabicOnly: isArabicOnly,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: isArabicOnly
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _summaryRow(
              tokens,
              l10n.commonMethod,
              _methodLabel(_method),
              isArabicOnly,
            ),
            _summaryRow(
              tokens,
              l10n.commonMadhab,
              _isHanafi ? l10n.onboardingMadhabHanafiTitle : 'Shafi',
              isArabicOnly,
            ),
            _summaryRow(
              tokens,
              l10n.commonLocation,
              _locationPermission == LocationPermission.deniedForever
                  ? l10n.onboardingSummaryLocationBlocked
                  : _locationServiceEnabled
                      ? l10n.commonReady
                      : l10n.commonPending,
              isArabicOnly,
            ),
            _summaryRow(
              tokens,
              l10n.commonNotifications,
              _notificationsEnabled
                  ? (_notificationsGranted
                      ? l10n.commonActivated
                      : l10n.onboardingSummaryNotificationsPrepared)
                  : l10n.commonDisabled,
              isArabicOnly,
            ),
          ],
      ),
      ),
    );
  }

  Widget _summaryRow(
    QiblaTokens tokens,
    String label,
    String value,
    bool isArabicOnly,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(CalculationMethod method) {
    final l10n = context.l10n;
    switch (method) {
      case CalculationMethod.muslim_world_league:
        return l10n.methodMuslimWorldLeague;
      case CalculationMethod.north_america:
        return l10n.methodNorthAmerica;
      case CalculationMethod.umm_al_qura:
        return l10n.methodUmmAlQura;
      case CalculationMethod.egyptian:
        return l10n.methodEgyptian;
      default:
        return method.name.replaceAll('_', ' ');
    }
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isArabicOnly,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Column(
      crossAxisAlignment:
          isArabicOnly ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.amiri(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            height: 1.6,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(child: SingleChildScrollView(child: child)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tokens,
    required this.isArabicOnly,
  });

  final IconData icon;
  final String title;
  final String body;
  final QiblaTokens tokens;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tokens.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: isArabicOnly
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.5,
                    color: tokens.textSecondary,
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    required this.actionLabel,
    required this.action,
    required this.tokens,
    required this.completed,
    required this.loading,
    required this.isArabicOnly,
  });

  final IconData icon;
  final String title;
  final String body;
  final String status;
  final String actionLabel;
  final Future<void> Function() action;
  final QiblaTokens tokens;
  final bool completed;
  final bool loading;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: completed ? tokens.primaryBorder : tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tokens.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                status,
                textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: completed ? tokens.primary : tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.5,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (!completed)
            OutlinedButton(
              onPressed: loading ? null : action,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.tokens,
    required this.onTap,
    required this.isArabicOnly,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final QiblaTokens tokens;
  final VoidCallback onTap;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? tokens.activeBg : tokens.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? tokens.activeBorder : tokens.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: isArabicOnly
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? tokens.primary : tokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
