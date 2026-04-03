import '../../../../l10n/l10n.dart';

class RecentLocation {
  const RecentLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.timestamp,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String timezone;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      label: json['label'] as String? ??
          appLocalizationsForCurrentLocale().recentLocationUnknown,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
