import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/firebase_messaging_provider.dart';

/// Widget that initializes Firebase Messaging when the app starts
class FirebaseMessagingInitializer extends StatefulWidget {
  final Widget child;

  const FirebaseMessagingInitializer({
    super.key,
    required this.child,
  });

  @override
  State<FirebaseMessagingInitializer> createState() =>
      _FirebaseMessagingInitializerState();
}

class _FirebaseMessagingInitializerState
    extends State<FirebaseMessagingInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMessaging();
    });
  }

  void _initializeMessaging() {
    final messagingProvider = Provider.of<FirebaseMessagingProvider>(
      context,
      listen: false,
    );

    // Initialize Firebase Messaging if not already initialized
    if (!messagingProvider.isInitialized) {
      messagingProvider.initializeMessaging();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseMessagingProvider>(
      builder: (context, provider, child) {
        // Show loading indicator if messaging is being initialized
        if (provider.isLoading) {
          debugPrint('🔄 Firebase Messaging is initializing...');
        }

        // Show error if initialization failed
        if (provider.error != null) {
          debugPrint('❌ Firebase Messaging error: ${provider.error}');
        }

        // Show success message and print token when initialized
        if (provider.isInitialized && provider.fcmToken != null) {
          debugPrint('✅ Firebase Messaging initialized successfully');
          // Print the token one more time for easy access
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.printTokenToConsole();
          });
        }

        return widget.child;
      },
    );
  }
}
