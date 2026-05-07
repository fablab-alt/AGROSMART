import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Manages connectivity state across the app
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Stream of connectivity status changes
  Stream<bool> get onConnectivityChanged {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _isConnected(results);
      if (online != _isOnline) {
        _isOnline = online;
        _connectivityController?.add(online);
        debugPrint('📶 Connectivity changed: ${online ? "Online" : "Offline"}');
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Check current connectivity (async)
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
    _connectivityController = null;
  }
}
