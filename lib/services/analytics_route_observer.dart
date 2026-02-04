import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'analytics_service.dart';

/// Mapa de rutas a módulos para screen_view.
/// Usado cuando RouteSettings.name no está disponible o para enriquecer.
const Map<String, String> _routeToModule = {
  '/splash': 'splash',
  '/login': 'auth',
  '/register': 'auth',
  '/forgot-password': 'auth',
  '/home': 'home',
  '/profile': 'profile',
  '/settings': 'settings',
  '/settings/about': 'settings',
  '/episode': 'podcast',
  '/youtube': 'youtube',
  '/course': 'academy',
  '/events': 'events',
  '/admin': 'admin',
  '/admin/modules': 'admin',
  '/admin/courses': 'admin',
  '/admin/events': 'admin',
};

String _getModuleFromPath(String path) {
  for (final entry in _routeToModule.entries) {
    if (path.startsWith(entry.key)) {
      return entry.value;
    }
  }
  return 'unknown';
}

/// Observer que envía screen_view a Firebase Analytics.
/// Compatible con GoRouter vía observers.
class AnalyticsRouteObserver extends NavigatorObserver {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _sendScreenView(previousRoute);
    }
  }

  void _sendScreenView(Route route) {
    final settings = route.settings;
    final name = settings.name ?? 'unknown';
    final module = _getModuleFromPath(name);

    AnalyticsService.logScreenView(
      screenName: name,
      module: module,
    );
  }
}
