import 'package:flutter/material.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';

/// A widget that automatically handles screenshot protection based on the route name
/// and security level of the screen
class ScreenshotProtectionWrapper extends StatefulWidget {
  final Widget child;
  final String routeName;
  final ScreenSecurityLevel securityLevel;

  const ScreenshotProtectionWrapper({
    Key? key,
    required this.child,
    required this.routeName,
    required this.securityLevel,
  }) : super(key: key);

  @override
  State<ScreenshotProtectionWrapper> createState() =>
      _ScreenshotProtectionWrapperState();
}

class _ScreenshotProtectionWrapperState
    extends State<ScreenshotProtectionWrapper> {
  @override
  void initState() {
    super.initState();
    _configureScreenProtection();
  }

  @override
  void didUpdateWidget(ScreenshotProtectionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeName != widget.routeName ||
        oldWidget.securityLevel != widget.securityLevel) {
      _configureScreenProtection();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateProtectionState();
  }

  void _configureScreenProtection() {
    // Configure based on security level
    ScreenshotProtectionService.configureProtectionBySecurityLevel(
        widget.routeName, widget.securityLevel);
  }

  void _updateProtectionState() {
    // Update protection state when this widget appears
    ScreenshotProtectionService.updateProtectionForRoute(widget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    // Just return the child widget - protection is handled via the service
    return widget.child;
  }
}
