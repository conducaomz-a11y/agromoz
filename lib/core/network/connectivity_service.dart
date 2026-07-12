import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus so the rest of the app depends on a
/// simple `isOnline` boolean and a stream, not on the plugin's enum shape.
class ConnectivityService {
  ConnectivityService._() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      if (online != _lastKnown) {
        _lastKnown = online;
        _controller.add(online);
      }
    });
  }
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _lastKnown = true;

  /// Emits true when the device goes online, false when it goes offline.
  Stream<bool> get onStatusChange => _controller.stream;

  /// One-shot check.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
