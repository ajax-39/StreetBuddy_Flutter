import 'package:flutter/material.dart';
import 'package:street_buddy/utils/connectivity_util.dart';
import 'package:street_buddy/widgets/connectivity_snackbar.dart';

class ConnectivityStatusScreen extends StatefulWidget {
  const ConnectivityStatusScreen({super.key});

  @override
  _ConnectivityStatusScreenState createState() =>
      _ConnectivityStatusScreenState();
}

class _ConnectivityStatusScreenState extends State<ConnectivityStatusScreen> {
  bool? _previouslyOnline;

  @override
  void initState() {
    super.initState();
    _showInitialStatus();
  }

  Future<void> _showInitialStatus() async {
    final status = await ConnectivityUtils.getCurrentConnectivity();
    if (mounted) {
      final isOnline = !status.contains('No Internet');
      _previouslyOnline = isOnline;
      ScaffoldMessenger.of(context)
          .showSnackBar(ConnectivitySnackBar.create(status, isOnline));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Status'),
      ),
      body: Center(
        child: StreamBuilder<String>(
          stream: ConnectivityUtils.connectivityStream,
          initialData: 'Checking...',
          builder: (context, snapshot) {
            final status = snapshot.data ?? 'Checking...';
            final isCurrentlyOnline = !status.contains('No Internet');

            if (_previouslyOnline != isCurrentlyOnline) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                    ConnectivitySnackBar.create(status, isCurrentlyOnline));
                _previouslyOnline = isCurrentlyOnline;
              });
            }

            return Text(
              status,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }
}
