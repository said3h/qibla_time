import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla de Dhikr (Tasbih) con diseño del prototipo
/// - Contador circular grande (155x155px)
/// - Rotación automática de frases cada 33
/// - Dots indicadores de ciclo
/// - Árabe + transliteración + significado
class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class DhikrPhrase {
  final String arabic;
  final String transliteration;
  final String meaning;

  const DhikrPhrase({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });
}

class _DhikrScreenState extends State<DhikrScreen> {
  int _count = 0;
  int _totalCount = 0;
  int _cycle = 1;
  final int _goal = 33;
  int _currentPhraseIndex = 0;

  // Frases del prototipo
  final List<DhikrPhrase> _phrases = [
    const DhikrPhrase(
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'SubhanAllah',
      meaning: 'Gloria a Allah',
    ),
    const DhikrPhrase(
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      meaning: 'Alabado sea Allah',
    ),
    const DhikrPhrase(
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      meaning: 'Allah es el más Grande',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCount = prefs.getInt(AppConstants.keyDhikrTotalCount) ?? 0;
    });
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
      
      // Rotar frase cada 33
      if (_count >= _goal) {
        HapticFeedback.heavyImpact();
        _rotatePhrase();
      }
    });
    _saveTotalCount();
  }

  void _rotatePhrase() {
    setState(() {
      _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      _count = 0;
      _cycle = _currentPhraseIndex + 1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
      _cycle = 1;
      _currentPhraseIndex = 0;
    });
  }

  DhikrPhrase get _currentPhrase => _phrases[_currentPhraseIndex];

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        title: Text(
          'Tasbih',
          style: GoogleFonts.amiri(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: tokens.primary),
            tooltip: 'Reiniciar',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Frase en árabe grande
              Text(
                _currentPhrase.arabic,
                style: GoogleFonts.amiri(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: tokens.primaryLight,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Transliteración
              Text(
                _currentPhrase.transliteration,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Significado
              Text(
                _currentPhrase.meaning,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: tokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Contador circular grande (155x155px como en el prototipo)
              GestureDetector(
                onTap: _increment,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tokens.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_count',
                          style: GoogleFonts.dmSans(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          'de $_goal',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dots indicadores de ciclo (3 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == _currentPhraseIndex;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive ? tokens.primary : tokens.bgSurface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? tokens.primary : tokens.borderMed,
                        width: 1,
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Total y ciclo
              Text(
                'Total: $_totalCount  •  Ciclo $_cycle/3',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textMuted,
                ),
              ),
              
              const Spacer(),
              
              // Lifetime total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, color: tokens.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lifetime: $_totalCount',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
