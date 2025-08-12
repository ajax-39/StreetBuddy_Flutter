import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsServiceChecker {
  final SupabaseClient _supabase;

  TermsServiceChecker({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Check if the current user has accepted the terms of service
  Future<bool> hasAcceptedTerms() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // No user is logged in, so no need to check
        return true;
      }

      final response = await _supabase
          .from('users')
          .select('terms_accepted')
          .eq('uid', currentUser.id)
          .single();

      return response['terms_accepted'] ?? false;
    } catch (e) {
      debugPrint('Error checking terms acceptance: $e');
      // Default to false if there's an error
      return false;
    }
  }

  /// Show terms of service dialog if the user hasn't accepted them
  Future<void> checkAndShowTermsDialog(BuildContext context) async {
    final bool termsAccepted = await hasAcceptedTerms();

    if (!termsAccepted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Terms of Service'),
          content: const Text(
              'Please review and accept our Terms of Service to continue using the app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Terms of Service screen
                Navigator.of(context).pushNamed('/terms-of-service');
              },
              child: const Text('Review Terms'),
            ),
          ],
        ),
      );
    }
  }
}
