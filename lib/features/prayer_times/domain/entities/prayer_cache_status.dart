class PrayerCacheStatus {
  const PrayerCacheStatus({
    required this.entryCount,
    required this.validUntil,
  });

  final int entryCount;
  final DateTime? validUntil;
}
