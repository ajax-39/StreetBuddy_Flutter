import 'package:flutter/material.dart';
import 'package:street_buddy/services/app_auth_service.dart';

class BiometricAuthWrapper extends StatefulWidget {
  final Widget child;

  const BiometricAuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<BiometricAuthWrapper> createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper>
    with WidgetsBindingObserver {
  final AppAuthService _appAuthService = AppAuthService();
  bool _isAuthenticating = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      _appAuthService.resetAuthentication();
      _authenticate();
    } else if (state == AppLifecycleState.paused) {
      // App is partially visible, about to enter background
      _appAuthService.resetAuthentication();
      _isAuthenticated = false;
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    final authenticated =
        await _appAuthService.authenticateWithBiometricsIfNeeded(context);

    setState(() {
      _isAuthenticated = authenticated;
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If still authenticating, show a loading indicator
    if (_isAuthenticating) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Verifying...'),
              ],
            ),
          ),
        ),
      );
    }

    // If authentication failed, show a retry screen
    if (!_isAuthenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, size: 60, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Authentication Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please use your fingerprint or face ID to unlock the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If authenticated or not required, show the app
    return widget.child;
  }
}
