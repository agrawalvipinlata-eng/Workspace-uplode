import 'package:connectivity_plus/connectivity_plus.dart';

/// Simple online/offline stream used for offline banners and driver
/// connection status.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> get isOnline =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  Future<bool> checkOnline() async =>
      _hasConnection(await _connectivity.checkConnectivity());

  bool _hasConnection(List<ConnectivityResult> results) => results.any(
        (ConnectivityResult r) =>
            r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
      );
}
