import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the phone has a network connection, as the OS reports it. The sync
/// engine syncs as soon as it comes back, and the List screen says when it's
/// gone.
///
/// "Connected" only means a network is up; the server can still be
/// unreachable, which the sync engine notices on its own.
abstract interface class NetworkStatus {
  Future<bool> isConnected();

  /// Emits whenever the connection comes or goes.
  Stream<bool> get changes;
}

/// [NetworkStatus] from the OS, through connectivity_plus.
class DeviceNetworkStatus implements NetworkStatus {
  DeviceNetworkStatus([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _connected(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isConnected() async => _connected(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes => _connectivity.onConnectivityChanged.map(_connected).distinct();
}
