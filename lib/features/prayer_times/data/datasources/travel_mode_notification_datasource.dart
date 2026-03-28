import '../../services/notification_service.dart';

class TravelModeNotificationDataSource {
  Future<void> showTravelDetected(String label) {
    return NotificationService.instance.showInstant(
      title: 'Qibla Time - Nueva ubicación',
      body: '$label - Horarios actualizados',
    );
  }
}
