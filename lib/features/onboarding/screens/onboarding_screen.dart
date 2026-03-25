import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
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

class _OnboardingScreenState extends State<OnboardingScreen> {
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

  static const _recommendedMethods = [
    CalculationMethod.muslim_world_league,
    CalculationMethod.north_america,
    CalculationMethod.umm_al_qura,
    CalculationMethod.egyptian,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt('calculation_method');
    final hanafi = prefs.getBool('madhab_hanafi') ?? false;
    final notifEnabled = await _settingsService.getNotificationsEnabled();
    final locationPermission = await Geolocator.checkPermission();
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    final notificationsGranted =
        await NotificationService.instance.areNotificationsEnabled();

    if (!mounted) return;
    setState(() {
      _method = methodIndex == null
          ? CalculationMethod.muslim_world_league
          : CalculationMethod.values[methodIndex];
      _isHanafi = hanafi;
      _notificationsEnabled = notifEnabled;
      _locationPermission = locationPermission;
      _locationServiceEnabled = locationServiceEnabled;
      _notificationsGranted = notificationsGranted;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 5) {
      await widget.onCompleted();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _requestLocation() async {
    setState(() => _busy = true);
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _locationPermission = permission;
      _locationServiceEnabled = enabled;
    });
  }

  Future<void> _requestNotifications() async {
    setState(() => _busy = true);
    await _settingsService.saveNotificationsEnabled(true);
    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _notificationsGranted = granted;
      _notificationsEnabled = true;
    });
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
                        value: (_step + 1) / 6,
                        minHeight: 6,
                        color: tokens.primary,
                        backgroundColor: tokens.bgSurface2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _busy ? null : () => widget.onSkipped(),
                    child: const Text('Saltar'),
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
                    _buildWelcome(tokens),
                    _buildPermissions(tokens),
                    _buildMethod(tokens),
                    _buildMadhab(tokens),
                    _buildAdhan(tokens),
                    _buildDone(tokens),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _step == 0 || _busy ? null : _back,
                      child: const Text('Atras'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _next,
                      child: Text(_step == 5 ? 'Entrar' : 'Continuar'),
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

  Widget _buildWelcome(QiblaTokens tokens) {
    return _StepScaffold(
      title: 'Bienvenido a QiblaTime',
      subtitle:
          'Horarios, Qibla, Coran y recordatorios en una app ligera para tu rutina diaria.',
      child: Column(
        children: [
          _FeatureCard(
            icon: Icons.access_time_rounded,
            title: 'Horarios fiables',
            body: 'Calculados segun tu ubicacion y metodo preferido.',
            tokens: tokens,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            icon: Icons.explore_rounded,
            title: 'Qibla y practica diaria',
            body: 'Brújula, tasbih, tracking y mas en el mismo flujo.',
            tokens: tokens,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            icon: Icons.notifications_active_outlined,
            title: 'Recordatorios utiles',
            body: 'Notificaciones de Adhan y ajustes listos desde el primer dia.',
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions(QiblaTokens tokens) {
    final locationReady = _locationServiceEnabled &&
        _locationPermission != LocationPermission.denied &&
        _locationPermission != LocationPermission.deniedForever;

    return _StepScaffold(
      title: 'Permisos importantes',
      subtitle:
          'Te pedimos solo lo necesario para calcular horarios, usar Qibla y avisarte a tiempo.',
      child: Column(
        children: [
          _PermissionCard(
            icon: Icons.place_outlined,
            title: 'Ubicacion',
            body: locationReady
                ? 'Lista para calcular horarios y Qibla.'
                : _locationPermission == LocationPermission.deniedForever
                    ? 'El permiso esta bloqueado. Puedes activarlo luego desde Ajustes del sistema.'
                    : !_locationServiceEnabled
                        ? 'El GPS del dispositivo esta desactivado. Puedes seguir y activarlo despues.'
                        : 'Necesaria para horarios precisos y direccion a La Meca.',
            status: locationReady
                ? 'Concedido'
                : _locationPermission == LocationPermission.deniedForever
                    ? 'Bloqueado'
                    : 'Pendiente',
            actionLabel: 'Permitir',
            action: _requestLocation,
            tokens: tokens,
            completed: locationReady,
            loading: _busy,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones',
            body: _notificationsGranted
                ? 'Listas para recordarte las oraciones.'
                : 'Asi puedes recibir tus avisos de Adhan y resumenes futuros.',
            status: _notificationsGranted ? 'Concedido' : 'Pendiente',
            actionLabel: 'Activar',
            action: _requestNotifications,
            tokens: tokens,
            completed: _notificationsGranted,
            loading: _busy,
          ),
        ],
      ),
    );
  }

  Widget _buildMethod(QiblaTokens tokens) {
    return _StepScaffold(
      title: 'Metodo de calculo',
      subtitle:
          'Puedes cambiarlo mas tarde, pero esto deja los horarios bien configurados desde hoy.',
      child: Column(
        children: _recommendedMethods.map((method) {
          final selected = method == _method;
          return _SelectableTile(
            title: _methodLabel(method),
            subtitle: selected ? 'Seleccionado ahora mismo' : 'Toque para usar este metodo',
            selected: selected,
            tokens: tokens,
            onTap: () => _persistMethod(method),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMadhab(QiblaTokens tokens) {
    return _StepScaffold(
      title: 'Madhab para Asr',
      subtitle:
          'Solo afecta al calculo de la oracion de Asr. Si dudas, puedes dejar Shafi y cambiarlo despues.',
      child: Column(
        children: [
          _SelectableTile(
            title: 'Shafi / Maliki / Hanbali',
            subtitle: 'La opcion mas comun para empezar',
            selected: !_isHanafi,
            tokens: tokens,
            onTap: () => _persistMadhab(false),
          ),
          _SelectableTile(
            title: 'Hanafi',
            subtitle: 'Usa el calculo Hanafi para Asr',
            selected: _isHanafi,
            tokens: tokens,
            onTap: () => _persistMadhab(true),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhan(QiblaTokens tokens) {
    return _StepScaffold(
      title: 'Adhan y avisos',
      subtitle:
          'QiblaTime puede avisarte de cada oracion y usar un Adhan suave por defecto. Luego podras elegir otro sonido.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificaciones de oracion',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Puedes activarlas o seguir sin ellas por ahora.',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prueba rapida del Adhan',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Se usara el sonido que tengas seleccionado. Puedes cambiarlo luego en Ajustes.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _togglePreview,
                  icon: Icon(_playingPreview ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  label: Text(_playingPreview ? 'Detener prueba' : 'Escuchar prueba'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(QiblaTokens tokens) {
    return _StepScaffold(
      title: 'Todo listo',
      subtitle:
          'Ya puedes empezar con tus horarios, tu Qibla y el seguimiento diario. Todo esto se puede ajustar despues.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(tokens, 'Metodo', _methodLabel(_method)),
            _summaryRow(tokens, 'Madhab', _isHanafi ? 'Hanafi' : 'Shafi'),
            _summaryRow(
              tokens,
              'Ubicacion',
              _locationPermission == LocationPermission.deniedForever
                  ? 'Bloqueada por ahora'
                  : _locationServiceEnabled
                      ? 'Lista'
                      : 'Pendiente',
            ),
            _summaryRow(
              tokens,
              'Notificaciones',
              _notificationsEnabled
                  ? (_notificationsGranted ? 'Activadas' : 'Preparadas')
                  : 'Desactivadas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(QiblaTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ),
          Text(
            value,
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
    switch (method) {
      case CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case CalculationMethod.north_america:
        return 'ISNA / Norteamerica';
      case CalculationMethod.umm_al_qura:
        return 'Umm al-Qura';
      case CalculationMethod.egyptian:
        return 'Egyptian Authority';
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
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.amiri(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
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
  });

  final IconData icon;
  final String title;
  final String body;
  final QiblaTokens tokens;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
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
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                status,
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
  });

  final String title;
  final String subtitle;
  final bool selected;
  final QiblaTokens tokens;
  final VoidCallback onTap;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
