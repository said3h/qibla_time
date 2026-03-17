import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  int _count = 0;
  int _totalCount = 0;
  final int _goal = 33;
  String _currentDhikr = 'SubhanAllah'; // Starting Default

  final List<String> _dhikrPhrases = [
    'SubhanAllah',
    'Alhamdulillah',
    'Allahu Akbar',
    'La ilaha illallah'
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
      if (_count >= _goal) {
        HapticFeedback.heavyImpact(); // Stronger feedback on reaching the goal (e.g., 33)
        _rotateDhikr();
      }
    });
    _saveTotalCount();
  }

  void _rotateDhikr() {
    int currentIndex = _dhikrPhrases.indexOf(_currentDhikr);
    int nextIndex = (currentIndex + 1) % _dhikrPhrases.length;
    _currentDhikr = _dhikrPhrases[nextIndex];
    _count = 0; // Reset count for the next phrase
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
    });
  }

  void _changePhrase(String newPhrase) {
    setState(() {
      _currentDhikr = newPhrase;
      _count = 0; // Usually resetting count on new phrase
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppTheme.backgroundWhite,
       appBar: AppBar(
         title: const Text('Dhikr (Tasbih)', style: TextStyle(fontWeight: FontWeight.bold)),
         actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
               tooltip: 'Reset Session',
              onPressed: _reset,
            ),
         ],
       ),
       body: SafeArea(
         child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: Column(
             children: [
               _buildPhraseSelector(),
               const Spacer(),
               Text(
                 _currentDhikr,
                 style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 16),
               Text(
                 'Goal: $_goal',
                 style: const TextStyle(fontSize: 18, color: AppTheme.textLight),
               ),
               const SizedBox(height: 40),
               GestureDetector(
                 onTap: _increment,
                 child: Container(
                   width: 250,
                   height: 250,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                     border: Border.all(color: AppTheme.accentGold, width: 8),
                     boxShadow: [
                       BoxShadow(
                         color: AppTheme.primaryGreen.withOpacity(0.15),
                         spreadRadius: 10,
                         blurRadius: 20,
                       ),
                     ],
                   ),
                   child: Center(
                     child: Text(
                       '$_count',
                       style: const TextStyle(
                         fontSize: 80,
                         fontWeight: FontWeight.bold,
                         color: AppTheme.textDark,
                       ),
                     ),
                   ),
                 ),
               ),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                 decoration: BoxDecoration(
                   color: AppTheme.primaryGreen.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.analytics, color: AppTheme.primaryGreen),
                     const SizedBox(width: 8),
                     Text(
                       'Lifetime Total: $_totalCount',
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 16),
             ],
           ),
         ),
       ),
    );
  }

  Widget _buildPhraseSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _dhikrPhrases.map((phrase) {
          final isSelected = _currentDhikr == phrase;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(phrase),
              selected: isSelected,
              onSelected: (selected) {
                 if (selected) _changePhrase(phrase);
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
