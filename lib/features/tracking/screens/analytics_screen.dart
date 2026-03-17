import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/tracking_service.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(prayerTrackingProvider);
    final notifier = ref.read(prayerTrackingProvider.notifier);
    
    final prayerStats = notifier.getPrayerStats();
    final monthlyStats = notifier.getMonthlyStats();
    final streak = notifier.getStreak();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Análisis Espiritual', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakSummary(streak),
            const SizedBox(height: 24),
            _buildSectionTitle('Consistencia (Hoy)'),
            const SizedBox(height: 12),
            _buildHeatmap(tracking),
            const SizedBox(height: 24),
            _buildSectionTitle('Por Rezo'),
            const SizedBox(height: 12),
            _buildPrayerBreakdown(prayerStats),
            const SizedBox(height: 24),
            _buildSectionTitle('Tendencia Mensual'),
            const SizedBox(height: 12),
            _buildMonthlyTrends(monthlyStats),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
    );
  }

  Widget _buildStreakSummary(int streak) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF006430)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 48),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak Días',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Racha de Oración Actual',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(Map<String, List<String>> data) {
    // Show last 30 days
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(30, (index) {
          final date = now.subtract(Duration(days: 29 - index));
          final key = "${date.year}-${date.month}-${date.day}";
          final count = data[key]?.length ?? 0;
          
          Color color;
          if (count == 0) color = Colors.grey.shade100;
          else if (count < 3) color = AppTheme.primaryGreen.withOpacity(0.3);
          else if (count < 5) color = AppTheme.primaryGreen.withOpacity(0.6);
          else color = AppTheme.primaryGreen;

          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPrayerBreakdown(Map<String, double> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: stats.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${(entry.value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.grey.shade100,
                    color: AppTheme.accentGold,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyTrends(Map<String, double> stats) {
    if (stats.isEmpty) return const Text('No hay datos suficientes.');
    
    return Column(
      children: stats.entries.map((entry) {
        final parts = entry.key.split('-');
        final monthName = DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              CircularProgressIndicator(
                value: entry.value,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade100,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 12),
              Text('${(entry.value * 100).toInt()}%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
