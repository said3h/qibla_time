import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/settings_service.dart';
import '../../domain/entities/ramadan_status.dart';

final ramadanModeAutomaticProvider = FutureProvider<bool>((ref) async {
  return SettingsService.instance.getRamadanModeAutomatic();
});

final ramadanModeForcedProvider = FutureProvider<bool>((ref) async {
  return SettingsService.instance.getRamadanModeForced();
});

final ramadanStatusProvider = FutureProvider<RamadanStatus>((ref) async {
  final automaticEnabled = await ref.watch(ramadanModeAutomaticProvider.future);
  final forced = await ref.watch(ramadanModeForcedProvider.future);
  return RamadanStatus.fromDate(
    DateTime.now(),
    automaticEnabled: automaticEnabled,
    forced: forced,
  );
});

final isRamadanProvider = FutureProvider<bool>((ref) async {
  return (await ref.watch(ramadanStatusProvider.future)).isEnabled;
});
