import '../../services/notification_service.dart';

class TravelModeNotificationDataSource {
  Future<void> showTravelDetected(String label) {
    return NotificationService.instance.showInstant(
      title: 'QiblaTime - Nueva ubicacion',
      body: '$label - Horarios actualizados',
    );
  }
}
