import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/spanish_date_labels.dart';
import '../../../l10n/l10n.dart';
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
  final DhikrService _service = DhikrService();
  final List<({String arabic, String transliteration, String meaning})>
      _phrases = const [
    (
      arabic: 'سُبْحَانَ اللّٰهِ',
      transliteration: 'SubhanAllah',
      meaning: 'SubhanAllah',
    ),
    (
      arabic: 'الْحَمْدُ لِلّٰهِ',
      transliteration: 'Alhamdulillah',
      meaning: 'Alhamdulillah',
    ),
    (
      arabic: 'اللّٰهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      meaning: 'Allahu Akbar',
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
    final l10n = context.l10n;

    HapticFeedback.lightImpact();

    final sessionGoal = snapshot.sessionGoal;
    final nextCount = _count + 1;
    final completesSession = nextCount % sessionGoal == 0;
    final optimistic = _optimisticIncrement(snapshot);

    setState(() {
      _snapshot = optimistic;
      _count = nextCount;
      if (completesSession) {
        _currentPhraseIndex = (_currentPhraseIndex + 1) % _activePhrases.length;
      }
    });

    if (completesSession) {
      _showMessage(l10n.dhikrSessionCycleCompleted);
    }
    if (!snapshot.dailyGoalReached && optimistic.dailyGoalReached) {
      _showMessage(l10n.dhikrDailyGoalCompletedMessage);
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
    _showMessage(context.l10n.dhikrSessionResetMessage);
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
    final l10n = context.l10n;
    if (snapshot.todayCount == 0) {
      return l10n.dhikrFeedbackStart;
    }
    if (snapshot.dailyGoalReached) {
      return l10n.dhikrFeedbackCompleted;
    }
    final progress = snapshot.todayCount / snapshot.dailyGoal;
    if (progress >= 0.75) {
      return l10n.dhikrFeedbackAlmostThere;
    }
    if (progress >= 0.4) {
      return l10n.dhikrFeedbackGoodPace;
    }
    if (_count > 0 && _count % snapshot.sessionGoal == 0) {
      return l10n.dhikrFeedbackCycleCompleted;
    }
    return l10n.dhikrFeedbackTakeYourTime;
  }

  String _dayLabel(DateTime date) {
    return SpanishDateLabels.shortWeekday(date);
  }

  String _localizedMeaning(String transliteration) {
    final l10n = context.l10n;
    return switch (transliteration) {
      'SubhanAllah' => l10n.dhikrMeaningSubhanAllah,
      'Alhamdulillah' => l10n.dhikrMeaningAlhamdulillah,
      'Allahu Akbar' => l10n.dhikrMeaningAllahuAkbar,
      _ => transliteration,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';

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
    final sessionCycleCount = _count % snapshot.sessionGoal;
    final sessionProgress = _count > 0 && sessionCycleCount == 0
        ? 1.0
        : (sessionCycleCount / snapshot.sessionGoal).clamp(0.0, 1.0);
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
                        l10n.dhikrTitle,
                        style: GoogleFonts.amiri(
                          fontSize: 26,
                          color: tokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.dhikrSubtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.dhikrResetSession,
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
            if (!isArabicOnly) ...[
              const SizedBox(height: 4),
              Text(
                phrase.transliteration,
                textAlign: TextAlign.center,
                style: tokens.transliterationTextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _localizedMeaning(phrase.transliteration),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textMuted,
                ),
              ),
            ],
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
                            '${l10n.dhikrSessionGoalShort}: ${snapshot.sessionGoal}',
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
              l10n.dhikrTodayCycle(
                snapshot.todayCount,
                _currentPhraseIndex + 1,
                _activePhrases.length,
              ),
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
                          l10n.dhikrDailyGoalTitle.toUpperCase(),
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
                label: Text(l10n.dhikrResetSession),
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
  });

  final int sessionGoal;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
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
            l10n.dhikrGoalsSection,
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
                  label: l10n.dhikrSessionGoalShort,
                  value: '$sessionGoal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GoalTile(
                  label: l10n.dhikrDailyGoalShort,
                  value: '$dailyGoal',
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.primaryBorder),
      ),
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
    final l10n = context.l10n;
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
            l10n.dhikrSummarySection,
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
                child: _HistoryStat(
                    label: l10n.commonToday, value: '${snapshot.todayCount}'),
              ),
              Expanded(
                child: _HistoryStat(
                  label: l10n.commonYesterday,
                  value: '${snapshot.yesterdayCount}',
                ),
              ),
              Expanded(
                child: _HistoryStat(
                  label: l10n.dhikrLast7Days,
                  value: '${snapshot.rollingWeekCount}',
                ),
              ),
              Expanded(
                child: _HistoryStat(
                  label: l10n.commonTotal,
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
                ? l10n.dhikrHistoryEmptyBody
                : l10n.dhikrHistorySavedBody,
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
