import 'package:flutter/material.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';

/// A route observer that automatically handles screenshot protection based on route changes
class ScreenshotProtectionRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateScreenshotProtection(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _updateScreenshotProtection(previousRoute);
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _updateScreenshotProtection(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _updateScreenshotProtection(Route<dynamic> route) {
    // Extract the route name from the route settings
    final routeName = route.settings.name;
    if (routeName != null) {
      // Update screenshot protection based on the current route
      ScreenshotProtectionService.updateProtectionForRoute(routeName);
    }
  }
}
