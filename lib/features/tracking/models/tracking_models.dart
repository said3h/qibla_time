// lib/features/tracking/models/tracking_models.dart

class HeatmapDay {
  final DateTime date;
  final int completed; // 0-5 oraciones completadas

  const HeatmapDay({required this.date, required this.completed});

  double get ratio => completed / 5.0;

  bool get isFull    => completed == 5;
  bool get isEmpty   => completed == 0;
  bool get isPartial => completed > 0 && completed < 5;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class MonthlyStats {
  final int month;
  final int year;
  final int prayersCompleted;  // total de oraciones marcadas
  final int fullDays;          // días con las 5 oraciones
  final int totalDays;         // días transcurridos en el mes

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.prayersCompleted,
    required this.fullDays,
    required this.totalDays,
  });

  // Máximo posible = 5 oraciones × días transcurridos
  int get maxPossible => totalDays * 5;

  double get completionRate =>
      maxPossible == 0 ? 0.0 : prayersCompleted / maxPossible;

  String get monthName {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[month];
  }
}
