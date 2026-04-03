import '../../../../l10n/l10n.dart';
import '../../services/notification_service.dart';

class TravelModeNotificationDataSource {
  Future<void> showTravelDetected(String label) {
    final l10n = appLocalizationsForCurrentLocale();

    return NotificationService.instance.showInstant(
      title: l10n.travelModeNotificationTitle,
      body: l10n.travelModeNotificationBody(label),
    );
  }
}
