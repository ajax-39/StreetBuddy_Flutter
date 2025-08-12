import 'package:flutter/material.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';
import 'package:street_buddy/services/settings_service.dart';

class ScreenshotProtectionNavigatorObserver extends NavigatorObserver {
  static const String _guidesRouteName = '/explore_guides_newscreen';
  final SettingsService _settingsService = SettingsService();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _handleRouteChange(route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(previousRoute?.settings.name, route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleRouteChange(oldRoute?.settings.name, newRoute?.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _handleRouteChange(route.settings.name, previousRoute?.settings.name);
  }

  void _handleRouteChange(String? fromRoute, String? toRoute) {
    // Only handle screenshot protection if the setting is enabled
    if (_settingsService.screenshotProtection) {
      if (fromRoute == _guidesRouteName && toRoute != _guidesRouteName) {
        ScreenshotProtectionService.forceDisableProtection();
        debugPrint(
            '📱 Navigated away from guides - screenshot protection disabled');
      }

      if (toRoute == _guidesRouteName) {
        ScreenshotProtectionService.enableProtection();
        debugPrint('📱 Navigated to guides - screenshot protection enabled');
      } else if (toRoute != null && toRoute != _guidesRouteName) {
        ScreenshotProtectionService.forceDisableProtection();
      }
    } else {
      // Always ensure protection is disabled if the setting is off
      ScreenshotProtectionService.forceDisableProtection();
    }
  }
}
