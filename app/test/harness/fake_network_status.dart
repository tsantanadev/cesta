import 'dart:async';

import 'package:cesta/src/sync/network_status.dart';

/// Seam 2 fake for the OS's connectivity report: starts connected, and
/// setting [connected] reports the change.
class FakeNetworkStatus implements NetworkStatus {
  final _changes = StreamController<bool>.broadcast();
  bool _connected = true;

  bool get connected => _connected;
  set connected(bool value) {
    if (value == _connected) return;
    _connected = value;
    _changes.add(value);
  }

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Stream<bool> get changes => _changes.stream;

  Future<void> close() => _changes.close();
}
