import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasConnection(dynamic result) {
  if (result is List<ConnectivityResult>) {
    return !result.contains(ConnectivityResult.none);
  }
  if (result is ConnectivityResult) {
    return result != ConnectivityResult.none;
  }
  return false;
}

final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield _hasConnection(await connectivity.checkConnectivity());
  } catch (_) {
    yield false;
  }

  yield* connectivity.onConnectivityChanged
      .map(_hasConnection)
      .transform<bool>(
        StreamTransformer<bool, bool>.fromHandlers(
          handleError: (_, __, sink) {
            sink.add(false);
          },
        ),
      );
});
