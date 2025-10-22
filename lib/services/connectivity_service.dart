import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor internet connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Stream controller for connectivity status
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _statusController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = _isConnectionAvailable(result);
    
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = _isConnectionAvailable(results);
      
      // Only emit if status actually changed
      if (wasConnected != _isConnected) {
        _statusController.add(_isConnected);
      }
    });
  }
  
  bool _isConnectionAvailable(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }
  
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for current connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

