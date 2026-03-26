import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../services/dhikr_service.dart';

class DhikrPhrase {
  const DhikrPhrase({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final String arabic;
  final String transliteration;
  final String meaning;
}

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({
    super.key,
    this.initialPhrase,
  });

  final DhikrPhrase? initialPhrase;

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  static const _sessionGoalPresets = [33, 66, 99, 100];
  static const _dailyGoalPresets = [99, 100, 200, 500];

  final DhikrService _service = DhikrService();
  final List<({String arabic, String transliteration, String meaning})>
      _phrases = const [
    (
      arabic: 'سُبْحَانَ اللّٰهِ',
      transliteration: 'SubhanAllah',
      meaning: 'Gloria a Allah',
    ),
    (
      arabic: 'الْحَمْدُ لِلّٰهِ',
      transliteration: 'Alhamdulillah',
      meaning: 'Alabado sea Allah',
    ),
    (
      arabic: 'اللّٰهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      meaning: 'Allah es el mas Grande',
    ),
  ];

  Future<void> _writeQueue = Future<void>.value();

  DhikrSnapshot? _snapshot;
  bool _isLoading = true;
  int _count = 0;
  int _currentPhraseIndex = 0;

  List<({String arabic, String transliteration, String meaning})>
      get _activePhrases {
    final initialPhrase = widget.initialPhrase;
    if (initialPhrase == null) return _phrases;

    return [
      (
        arabic: initialPhrase.arabic,
        transliteration: initialPhrase.transliteration,
        meaning: initialPhrase.meaning,
      ),
      ..._phrases.where(
        (phrase) => phrase.transliteration != initialPhrase.transliteration,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await _service.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isLoading = false;
      _count = 0;
    });
  }

  void _increment() {
    final snapshot = _snapshot;
    if (snapshot == null) return;

    HapticFeedback.lightImpact();

    final sessionGoal = snapshot.sessionGoal;
    final nextCount = _count + 1;
    final completesSession = nextCount >= sessionGoal;
    final optimistic = _optimisticIncrement(snapshot);

    setState(() {
      _snapshot = optimistic;
      _count = completesSession ? 0 : nextCount;
      if (completesSession) {
        _currentPhraseIndex =
            (_currentPhraseIndex + 1) % _activePhrases.length;
      }
    });

    if (completesSession) {
      _showMessage('Ciclo completado. Pasamos al siguiente dhikr.');
    }
    if (!snapshot.dailyGoalReached && optimistic.dailyGoalReached) {
      _showMessage('Meta diaria completada. Puedes seguir si lo deseas.');
    }

    _writeQueue = _writeQueue.then((_) async {
      final persisted = await _service.increment();
      if (!mounted) return;
      final current = _snapshot;
      if (current == null || persisted.todayCount >= current.todayCount) {
        setState(() {
          _snapshot = persisted;
        });
      }
    });
  }

  void _resetSession() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
      _currentPhraseIndex = 0;
    });
    _showMessage('Sesion reiniciada. Tu historial diario sigue guardado.');
  }

  Future<void> _pickGoal({required bool daily}) async {
    final snapshot = _snapshot;
    if (snapshot == null) return;

    final tokens = QiblaThemes.current;
    final currentValue = daily ? snapshot.dailyGoal : snapshot.sessionGoal;
    final presets = daily ? _dailyGoalPresets : _sessionGoalPresets;
    final title = daily ? 'Meta diaria' : 'Meta por sesion';
    final helper = daily
        ? 'Cuantas repeticiones quieres completar a lo largo del dia.'
        : 'Cuantas repeticiones quieres por ciclo antes de pasar al siguiente dhikr.';

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  helper,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final value in presets)
                      _GoalPresetChip(
                        label: '$value',
                        selected: value == currentValue,
                        onTap: () => Navigator.of(context).pop(value),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () async {
                    final custom = await _showCustomGoalDialog(
                      title: title,
                      initialValue: currentValue,
                    );
                    if (!context.mounted || custom == null) return;
                    Navigator.of(context).pop(custom);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Elegir valor personalizado'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final updated = await _service.updateGoals(
      sessionGoal: daily ? null : selected,
      dailyGoal: daily ? selected : null,
    );
    if (!mounted) return;

    setState(() {
      _snapshot = updated;
      if (!daily) {
        _count = updated.sessionGoal <= 0 ? 0 : _count % updated.sessionGoal;
      }
    });

    _showMessage(
      daily
          ? 'Meta diaria ajustada a $selected repeticiones.'
          : 'Meta por sesion ajustada a $selected repeticiones.',
    );
  }

  Future<int?> _showCustomGoalDialog({
    required String title,
    required int initialValue,
  }) async {
    final controller = TextEditingController(text: '$initialValue');

    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Numero de repeticiones',
              hintText: 'Ejemplo: 150',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return value;
  }

  DhikrSnapshot _optimisticIncrement(DhikrSnapshot snapshot) {
    final recentDays = [...snapshot.recentDays];
    if (recentDays.isNotEmpty) {
      final today = recentDays.last;
      recentDays[recentDays.length - 1] = DhikrDayStat(
        date: today.date,
        count: today.count + 1,
      );
    }

    return DhikrSnapshot(
      lifetimeTotal: snapshot.lifetimeTotal + 1,
      todayCount: snapshot.todayCount + 1,
      yesterdayCount: snapshot.yesterdayCount,
      rollingWeekCount: snapshot.rollingWeekCount + 1,
      sessionGoal: snapshot.sessionGoal,
      dailyGoal: snapshot.dailyGoal,
      recentDays: recentDays,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _feedbackText(DhikrSnapshot snapshot) {
    if (snapshot.todayCount == 0) {
      return 'Empieza con unas repeticiones y guardaremos tu avance de hoy.';
    }
    if (snapshot.dailyGoalReached) {
      return 'Meta diaria completada. Si quieres, continua con calma.';
    }
    final progress = snapshot.todayCount / snapshot.dailyGoal;
    if (progress >= 0.75) {
      return 'Ya casi completas tu objetivo diario.';
    }
    if (progress >= 0.4) {
      return 'Buen ritmo. Cada repeticion cuenta.';
    }
    if (_count == 0) {
      return 'Ciclo completado. Puedes seguir con el siguiente dhikr.';
    }
    return 'Avanza a tu ritmo y vuelve cuando quieras.';
  }

  String _dayLabel(DateTime date) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    if (_isLoading || _snapshot == null) {
      return Scaffold(
        backgroundColor: tokens.bgPage,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: tokens.primary),
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final phrase = _activePhrases[_currentPhraseIndex];
    final sessionProgress = snapshot.sessionGoal <= 0
        ? 0.0
        : (_count / snapshot.sessionGoal).clamp(0.0, 1.0);
    final dailyProgress = snapshot.dailyGoal <= 0
        ? 0.0
        : (snapshot.todayCount / snapshot.dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasbih',
                        style: GoogleFonts.amiri(
                          fontSize: 26,
                          color: tokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tasbih diario · progreso y constancia',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reiniciar sesion',
                  onPressed: _resetSession,
                  icon: Icon(Icons.refresh, color: tokens.primary),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              phrase.arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 32,
                color: tokens.primaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phrase.transliteration,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phrase.meaning,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _increment,
              child: SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: CustomPaint(
                        painter: _RingPainter(
                          backgroundColor: tokens.bgSurface2,
                          progressColor: tokens.primary,
                          progress: sessionProgress,
                        ),
                      ),
                    ),
                    Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.bgSurface,
                        border: Border.all(color: tokens.primaryBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_count',
                            style: GoogleFonts.dmSans(
                              fontSize: 54,
                              fontWeight: FontWeight.w300,
                              color: tokens.textPrimary,
                            ),
                          ),
                          Text(
                            'de ${snapshot.sessionGoal}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _activePhrases.length,
                (index) => Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhraseIndex
                        ? tokens.primary
                        : tokens.bgSurface2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hoy: ${snapshot.todayCount} · Ciclo ${_currentPhraseIndex + 1}/${_activePhrases.length}',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _feedbackText(snapshot),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            _GoalCard(
              sessionGoal: snapshot.sessionGoal,
              dailyGoal: snapshot.dailyGoal,
              onSessionTap: () => _pickGoal(daily: false),
              onDailyTap: () => _pickGoal(daily: true),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'META DIARIA',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${snapshot.todayCount} / ${snapshot.dailyGoal}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: dailyProgress,
                      color: tokens.primary,
                      backgroundColor: tokens.bgSurface2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _HistoryCard(
              snapshot: snapshot,
              dayLabelBuilder: _dayLabel,
            ),
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton.icon(
                onPressed: _resetSession,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.borderMed),
                  foregroundColor: tokens.textSecondary,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reiniciar sesion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.sessionGoal,
    required this.dailyGoal,
    required this.onSessionTap,
    required this.onDailyTap,
  });

  final int sessionGoal;
  final int dailyGoal;
  final VoidCallback onSessionTap;
  final VoidCallback onDailyTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'METAS',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.2,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GoalTile(
                  label: 'Por sesion',
                  value: '$sessionGoal',
                  onTap: onSessionTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GoalTile(
                  label: 'Diaria',
                  value: '$dailyGoal',
                  onTap: onDailyTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.tune, size: 18, color: tokens.primary),
          ],
        ),
      ),
    );
  }
}

class _GoalPresetChip extends StatelessWidget {
  const _GoalPresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? tokens.primaryBg : tokens.bgSurface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tokens.primaryBorder : tokens.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? tokens.primary : tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.snapshot,
    required this.dayLabelBuilder,
  });

  final DhikrSnapshot snapshot;
  final String Function(DateTime) dayLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final maxCount = snapshot.recentDays.fold<int>(
      1,
      (currentMax, item) => math.max(currentMax, item.count),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.2,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HistoryStat(label: 'Hoy', value: '${snapshot.todayCount}'),
              ),
              Expanded(
                child: _HistoryStat(
                  label: 'Ayer',
                  value: '${snapshot.yesterdayCount}',
                ),
              ),
              Expanded(
                child: _HistoryStat(
                  label: '7 dias',
                  value: '${snapshot.rollingWeekCount}',
                ),
              ),
              Expanded(
                child: _HistoryStat(
                  label: 'Total',
                  value: '${snapshot.lifetimeTotal}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in snapshot.recentDays)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 52,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              height: day.count == 0
                                  ? 6
                                  : (day.count / maxCount) * 44 + 8,
                              decoration: BoxDecoration(
                                color: day.count > 0
                                    ? tokens.primary
                                    : tokens.bgSurface2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabelBuilder(day.date),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            snapshot.todayCount == 0
                ? 'Todavia no hay repeticiones hoy. El primer toque ya empezara tu registro diario.'
                : 'Tu historial diario se guarda automaticamente para que puedas seguir tu constancia.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.5,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9,
            letterSpacing: 1.0,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.backgroundColor,
    required this.progressColor,
    required this.progress,
  });

  final Color backgroundColor;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 6.0;
    final background = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final foreground = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(strokeWidth),
      -math.pi / 2,
      math.pi * 2,
      false,
      background,
    );
    canvas.drawArc(
      rect.deflate(strokeWidth),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
