// lib/features/focus/screens/focus_mode_screen.dart
//
// Pantalla de modo enfoque:
// - Fondo negro minimalista
// - Contador de rak'ahs via sensor de proximidad (sujud detection)
// - Hold-to-exit con animación de círculo SVG
// - Fallback manual si el sensor no está disponible
// - DND automático al entrar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/focus_service.dart';

// Duración que hay que mantener pulsado para salir (ms)
const _kHoldDuration = Duration(milliseconds: 2000);

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen>
    with TickerProviderStateMixin {

  // ── Animación del círculo hold-to-exit ──────────────────────
  late AnimationController _holdController;
  late Animation<double>    _holdAnimation;
  bool _isHolding = false;

  // ── Animación de pulso en el contador ──────────────────────
  late AnimationController _pulseController;
  late Animation<double>    _pulseAnimation;

  // ── Modo manual (fallback) ───────────────────────────────────
  bool _manualMode = false;
  int  _manualSujudCount = 0; // 0 o 1 dentro de la rak'ah actual

  @override
  void initState() {
    super.initState();

    // Círculo hold-to-exit
    _holdController = AnimationController(
      vsync: this,
      duration: _kHoldDuration,
    );
    _holdAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _holdController, curve: Curves.easeInOut),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _exitFocus();
      }
    });

    // Pulso del contador al añadir rak'ah
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _pulseController.reverse();
    });

    // Activar DND y modo enfoque
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusProvider.notifier).activate();
    });

    // Mantener pantalla encendida
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Salir del modo enfoque ───────────────────────────────────

  void _exitFocus() {
    HapticFeedback.heavyImpact();
    ref.read(focusProvider.notifier).deactivate();
    Navigator.of(context).pop();
  }

  // ── Hold-to-exit: inicio ─────────────────────────────────────

  void _onHoldStart() {
    setState(() => _isHolding = true);
    HapticFeedback.selectionClick();
    _holdController.forward(from: 0.0);
  }

  // ── Hold-to-exit: fin (soltó antes de completar) ─────────────

  void _onHoldEnd() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
      setState(() => _isHolding = false);
    }
  }

  // ── Modo manual: simular sujud ────────────────────────────────

  void _manualSujud() {
    HapticFeedback.lightImpact();
    setState(() {
      _manualSujudCount++;
      if (_manualSujudCount >= 2) {
        _manualSujudCount = 0;
        ref.read(focusProvider.notifier).incrementRakahs();
        _pulseController.forward(from: 0.0);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusProvider);

    // Pulso automático cuando cambia el contador
    ref.listen(focusProvider.select((s) => s.rakahs), (prev, next) {
      if (next != prev) _pulseController.forward(from: 0.0);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [

            // ── Contenido principal ────────────────────────────
            Column(
              children: [
                const Spacer(),

                Text(
                  'RAKAHA',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.42),
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Árabe: "خشوع" (khushu — concentración espiritual)
                Text(
                  'خشوع',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 8),

                // Contador de rak'ahs
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    '${focus.rakahs}',
                    style: GoogleFonts.dmSans(
                      fontSize: 96,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),

                Text(
                  focus.rakahs == 1 ? "rak'ah" : "rak'ahs",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.45),
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 32),

                // Estado del sensor / sujud
                _SensorStatus(focus: focus, manualMode: _manualMode),

                const Spacer(),

                // ── Botones inferiores ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      // Toggle modo manual
                      _ManualModeToggle(
                        isManual: _manualMode,
                        sujudCount: _manualSujudCount,
                        onToggle: () =>
                            setState(() => _manualMode = !_manualMode),
                        onSujud: _manualSujud,
                      ),

                      // Hold-to-exit (centro)
                      _HoldToExitButton(
                        holdAnimation: _holdAnimation,
                        isHolding: _isHolding,
                        onHoldStart: _onHoldStart,
                        onHoldEnd: _onHoldEnd,
                      ),

                      // DND status
                      _DndIndicator(isActive: focus.dndActive),
                    ],
                  ),
                ),
              ],
            ),

            // ── Overlay DND pedido pero denegado ──────────────
            if (focus.isActive && !focus.dndActive)
              const _DndDeniedBanner(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOLD-TO-EXIT BUTTON — el fix principal
// ══════════════════════════════════════════════════════════════

class _HoldToExitButton extends StatelessWidget {
  final Animation<double> holdAnimation;
  final bool isHolding;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _HoldToExitButton({
    required this.holdAnimation,
    required this.isHolding,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd:   (_) => onHoldEnd(),
      onLongPressCancel: onHoldEnd,
      child: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: holdAnimation,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [

                // Círculo de fondo (gris oscuro)
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 2,
                    ),
                  ),
                ),

                // Arco de progreso (blanco girando)
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    value: holdAnimation.value,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(
                        Colors.white.withOpacity(0.4),
                        Colors.white,
                        holdAnimation.value,
                      )!,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),

                // Icono interior
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: holdAnimation.value > 0.05
                      ? Icon(
                          Icons.close_rounded,
                          color: Colors.white
                              .withOpacity(0.4 + holdAnimation.value * 0.6),
                          size: 28,
                          key: const ValueKey('close'),
                        )
                      : Icon(
                          Icons.stop_rounded,
                          color: Colors.white.withOpacity(0.35),
                          size: 28,
                          key: const ValueKey('stop'),
                        ),
                ),

                // Texto "mantén" debajo del círculo
                Positioned(
                  bottom: -20,
                  child: Text(
                    isHolding ? 'suelta para cancelar' : 'mantén para salir',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.30),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SENSOR STATUS — muestra si se detectó el primer sujud
// ══════════════════════════════════════════════════════════════

class _SensorStatus extends StatelessWidget {
  final FocusState focus;
  final bool manualMode;

  const _SensorStatus({required this.focus, required this.manualMode});

  @override
  Widget build(BuildContext context) {
    if (manualMode) {
      return Text(
        'Modo manual activo',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withOpacity(0.3),
          letterSpacing: 1.5,
        ),
      );
    }

    if (!focus.sensorAvailable) {
      return Text(
        'SENSOR NO DISPONIBLE · USA MODO MANUAL',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.36),
          letterSpacing: 1.6,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Estado del sensor
    final label = focus.isNear
        ? '● primer sujud detectado'
        : '○ esperando sujud...';

    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        color: focus.isNear
            ? Colors.white.withOpacity(0.6)
            : Colors.white.withOpacity(0.2),
        letterSpacing: 1.8,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MANUAL MODE TOGGLE
// ══════════════════════════════════════════════════════════════

class _ManualModeToggle extends StatelessWidget {
  final bool isManual;
  final int  sujudCount;
  final VoidCallback onToggle;
  final VoidCallback onSujud;

  const _ManualModeToggle({
    required this.isManual,
    required this.sujudCount,
    required this.onToggle,
    required this.onSujud,
  });

  @override
  Widget build(BuildContext context) {
    if (isManual) {
      // En modo manual: botón de sujud + toggle para volver
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onSujud,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  sujudCount == 0 ? '1°' : '2°',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              'sensor',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.25),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      );
    }

    // Modo sensor: botón para cambiar a manual
    return GestureDetector(
      onTap: onToggle,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Colors.white.withOpacity(0.20),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              'manual',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.20),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DND INDICATOR
// ══════════════════════════════════════════════════════════════

class _DndIndicator extends StatelessWidget {
  final bool isActive;

  const _DndIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.do_not_disturb_on : Icons.notifications_none,
            color: Colors.white.withOpacity(isActive ? 0.45 : 0.15),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'dnd' : 'notif',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(isActive ? 0.35 : 0.15),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DND DENEGADO — banner superior
// ══════════════════════════════════════════════════════════════

class _DndDeniedBanner extends StatelessWidget {
  const _DndDeniedBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withOpacity(0.05),
        child: Text(
          'Activa el modo No Molestar manualmente para evitar interrupciones',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.35),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
