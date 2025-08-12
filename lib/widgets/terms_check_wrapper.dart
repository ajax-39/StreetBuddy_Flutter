import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/services/terms_service_checker.dart';

class TermsCheckWrapper extends StatefulWidget {
  final Widget child;

  const TermsCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<TermsCheckWrapper> createState() => _TermsCheckWrapperState();
}

class _TermsCheckWrapperState extends State<TermsCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    // Add a small delay to make sure everything is initialized properly
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if user is signed in
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (authProvider.isSignedIn) {
      // Check if terms have been accepted
      final termsChecker = TermsServiceChecker();
      await termsChecker.checkAndShowTermsDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
