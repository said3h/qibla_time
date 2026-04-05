import '../../../../core/localization/locale_controller.dart';
import '../../domain/entities/prayer_name.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/usecases/get_next_prayer_info.dart';
import '../../services/widget_sync_service.dart';

class PrayerWidgetDataSource {
  PrayerWidgetDataSource({
    WidgetSyncService? widgetSyncService,
    GetNextPrayerInfoUseCase? nextPrayerInfoUseCase,
  })  : _widgetSyncService = widgetSyncService ?? WidgetSyncService(),
        _nextPrayerInfoUseCase =
            nextPrayerInfoUseCase ?? const GetNextPrayerInfoUseCase();

  final WidgetSyncService _widgetSyncService;
  final GetNextPrayerInfoUseCase _nextPrayerInfoUseCase;

  Future<void> sync(PrayerSchedule schedule) async {
    final nextPrayer = _nextPrayerInfoUseCase.call(schedule);
    if (nextPrayer == null) {
      return;
    }

    await _widgetSyncService.syncNextPrayer(
      PrayerSnapshot(
        name: nextPrayer.prayer
            .localizedDisplayName(AppLocaleController.effectiveLanguageCode())
            .toUpperCase(),
        timeLabel:
            '${nextPrayer.time.hour.toString().padLeft(2, '0')}:${nextPrayer.time.minute.toString().padLeft(2, '0')}',
        countdownLabel:
            '${nextPrayer.remaining.inHours}h ${nextPrayer.remaining.inMinutes.remainder(60)}m',
        themeKey: nextPrayer.prayer.key,
      ),
    );
  }
}
