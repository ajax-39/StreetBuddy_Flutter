import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityUtils {
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  factory ConnectivityUtils() => _instance;
  ConnectivityUtils._internal();

  static final _connectivityStreamController =
      StreamController<String>.broadcast();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Function(String)? onStatusChanged;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results.first);
      },
    );
  }

  // New static method to get connectivity stream
  static Stream<String> get connectivityStream {
    return _connectivityStreamController.stream;
  }

  // New static method for one-time connectivity check
  static Future<String> getCurrentConnectivity() async {
    return await _instance.checkInitialConnectivity();
  }

  Future<String> checkInitialConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      return _getConnectionString(results.first);
    } catch (e) {
      return 'Failed to get connectivity: $e';
    }
  }

  String _getConnectionString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Network';
      case ConnectivityResult.wifi:
        return 'Connected to Wi-Fi';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Connection Status';
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final status = _getConnectionString(result);
    onStatusChanged?.call(status);
    _connectivityStreamController.add(status); // Add status to stream
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityStreamController.close();
  }
}
