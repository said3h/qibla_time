import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/l10n.dart';
import '../services/focus_service.dart';

const _kHoldToExitDuration = Duration(seconds: 2);

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  bool _isExiting = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(focusProvider.notifier).activate());

    _exitController = AnimationController(
      vsync: this,
      duration: _kHoldToExitDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _closeRakaha();
        }
      });
  }

  @override
  void dispose() {
    _exitController.dispose();
    ref.read(focusProvider.notifier).deactivate();
    super.dispose();
  }

  void _closeRakaha() {
    ref.read(focusProvider.notifier).deactivate();
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_allowExit) {
        return;
      }
      Navigator.of(context).pop();
    });
  }

  void _onExitHoldStart() {
    setState(() => _isExiting = true);
    _exitController.forward(from: 0.0);
  }

  void _onExitHoldEnd() {
    if (_exitController.status != AnimationStatus.completed) {
      _exitController.reverse();
      setState(() => _isExiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusProvider);
    final l10n = context.l10n;

    return PopScope(
      canPop: _allowExit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              if (focus.dndActive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.do_not_disturb_on,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.focusModeDndActive,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(
                    Icons.notifications_off,
                    size: 14,
                    color: Colors.amber,
                  ),
                  label: Text(
                    l10n.focusModeOpenDndSettings,
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text(
                      l10n.focusModeTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${focus.rakahs}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 160,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    if (focus.sujudCount > 0)
                      Text(
                        l10n.focusModeSujudCount,
                        style: TextStyle(
                          color: Colors.teal.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (!focus.dndActive) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.focusModeDndHint,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.22),
                          fontSize: 10,
                          letterSpacing: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: GestureDetector(
                  onLongPressStart: (_) => _onExitHoldStart(),
                  onLongPressEnd: (_) => _onExitHoldEnd(),
                  onLongPressCancel: _onExitHoldEnd,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _exitController,
                        builder: (context, _) {
                          return SizedBox(
                            width: 92,
                            height: 92,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size.square(92),
                                  painter: _HoldRingPainter(
                                    progress: _exitController.value,
                                    isActive: _isExiting,
                                  ),
                                ),
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                      _isExiting ? 0.08 : 0.05,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        _isExiting ? 0.22 : 0.12,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.power_settings_new,
                                    color: Colors.white.withOpacity(
                                      _isExiting ? 0.96 : 0.52,
                                    ),
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isExiting
                            ? l10n.focusModeReleaseToCancel
                            : l10n.focusModeHoldToExit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({
    required this.progress,
    required this.isActive,
  });

  final double progress;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = isActive ? 4.0 : 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = Color.lerp(
        Colors.white.withOpacity(0.45),
        Colors.white,
        progress,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HoldRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
