import 'package:flutter/material.dart';
import 'package:street_buddy/utils/connectivity_util.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  bool? _isOnline;

  @override
  void initState() {
    super.initState();
    _setupConnectivity();
  }

  void _showConnectivitySnackBar(bool isOnline) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Back Online' : 'No Internet Connection',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isOnline ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _setupConnectivity() async {
    _connectivityUtils.onStatusChanged = (String status) {
      if (!mounted) return;

      bool isCurrentlyOnline = !status.contains('No Internet');
      debugPrint('Connectivity changed: $status (Online: $isCurrentlyOnline)');

      if (_isOnline != isCurrentlyOnline) {
        setState(() {
          _isOnline = isCurrentlyOnline;
        });
        _showConnectivitySnackBar(isCurrentlyOnline);
      }
    };

    _connectivityUtils.initialize();
    String initialStatus = await _connectivityUtils.checkInitialConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !initialStatus.contains('No Internet');
      });
    }
  }

  @override
  void dispose() {
    _connectivityUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
