import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  final List<({String arabic, String transliteration, String meaning})> _phrases = const [
    (arabic: 'سُبْحَانَ اللَّه', transliteration: 'SubhanAllah', meaning: 'Gloria a Allah'),
    (arabic: 'اَلْحَمْدُ لِلَّهِ', transliteration: 'Alhamdulillah', meaning: 'Alabado sea Allah'),
    (arabic: 'اللَّهُ أَكْبَر', transliteration: 'Allahu Akbar', meaning: 'Allah es el mas Grande'),
  ];

  int _count = 0;
  int _totalCount = 0;
  int _currentPhraseIndex = 0;
  final int _goal = 33;
  final int _dailyGoal = 99;

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _totalCount = prefs.getInt(AppConstants.keyDhikrTotalCount) ?? 0);
  }

  Future<void> _saveTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDhikrTotalCount, _totalCount);
  }

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      _totalCount++;
      if (_count >= _goal) {
        _count = 0;
        _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      }
    });
    _saveTotalCount();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
      _totalCount = 0;
      _currentPhraseIndex = 0;
    });
    _saveTotalCount();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final phrase = _phrases[_currentPhraseIndex];
    final progress = _count / _goal;
    final dailyProgress = (_totalCount / _dailyGoal).clamp(0.0, 1.0);

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
                      Text('Tasbih', style: GoogleFonts.amiri(fontSize: 26, color: tokens.primary, fontWeight: FontWeight.bold)),
                      Text('تسبيح · Dhikr', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                    ],
                  ),
                ),
                IconButton(onPressed: _reset, icon: Icon(Icons.refresh, color: tokens.primary)),
              ],
            ),
            const SizedBox(height: 18),
            Text(phrase.arabic, textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: 32, color: tokens.primaryLight)),
            const SizedBox(height: 4),
            Text(phrase.transliteration, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: tokens.textSecondary)),
            const SizedBox(height: 2),
            Text(phrase.meaning, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textMuted)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _increment,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: _RingPainter(
                          backgroundColor: tokens.bgSurface2,
                          progressColor: tokens.primary,
                          progress: progress,
                        ),
                      ),
                    ),
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.bgSurface,
                        border: Border.all(color: tokens.primaryBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$_count', style: GoogleFonts.dmSans(fontSize: 54, fontWeight: FontWeight.w300, color: tokens.textPrimary)),
                          Text('de $_goal', style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary)),
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
                3,
                (index) => Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhraseIndex ? tokens.primary : tokens.bgSurface2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total hoy: $_totalCount · Ciclo ${_currentPhraseIndex + 1}/3',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary),
            ),
            const SizedBox(height: 16),
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
                        child: Text('META DIARIA', style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.2, color: tokens.textSecondary)),
                      ),
                      Text('$_totalCount / $_dailyGoal', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: dailyProgress,
                      color: tokens.primary,
                      backgroundColor: tokens.bgSurface2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.borderMed),
                  foregroundColor: tokens.textSecondary,
                ),
                child: const Text('Reiniciar'),
              ),
            ),
          ],
        ),
      ),
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

    canvas.drawArc(rect.deflate(strokeWidth), -math.pi / 2, math.pi * 2, false, background);
    canvas.drawArc(rect.deflate(strokeWidth), -math.pi / 2, math.pi * 2 * progress, false, foreground);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
