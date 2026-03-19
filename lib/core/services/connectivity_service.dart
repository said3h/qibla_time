import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasConnection(dynamic result) {
  if (result is List<ConnectivityResult>) {
    return !result.contains(ConnectivityResult.none);
  }
  if (result is ConnectivityResult) {
    return result != ConnectivityResult.none;
  }
  return true;
}

final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasConnection(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});
