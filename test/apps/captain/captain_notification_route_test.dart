import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_app_router.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_routes.dart';

/// `FcmService._onTap` pushes `notifications.action_url` verbatim. The captain
/// notification trigger (`on_operation_trip_change`) stamps `'/trips'` on the
/// assignment push — "تم إسنادك لرحلة جديدة", the most frequent notification a
/// captain receives — and `'/trips'` matched no captain route name.
/// `generateRoute` returned null and Flutter threw "Could not find a generator
/// for route", so tapping the app's most common push was a dead end.
///
/// These tests fail without the alias.
void main() {
  Route<dynamic>? routeFor(String name) =>
      CaptainAppRouter.generateRoute(RouteSettings(name: name));

  group('server-sent notification paths', () {
    test('the assignment action_url the backend actually sends resolves', () {
      // Not a literal by accident: this is the exact string in
      // supabase/migrations/20260706140000_notification_event_engine.sql.
      expect(CaptainRoutes.assignmentAlias, '/trips');
      expect(routeFor(CaptainRoutes.assignmentAlias), isNotNull);
    });

    test('it lands on the same screen as home, not a stub', () {
      expect(routeFor(CaptainRoutes.assignmentAlias).runtimeType,
          routeFor(CaptainRoutes.home).runtimeType);
    });

    test('every route the captain app names still resolves', () {
      // A route constant that generateRoute cannot build is a dead link the
      // moment something navigates to it.
      for (final route in const [
        CaptainRoutes.home,
        CaptainRoutes.requestAccess,
        CaptainRoutes.notifications,
      ]) {
        expect(routeFor(route), isNotNull, reason: '$route did not resolve');
      }
    });

    test('a genuinely unknown path still returns null rather than silently '
        'landing somewhere', () {
      // The alias must not become a catch-all: an unmapped path is a bug to
      // surface, not to swallow.
      expect(routeFor('/captain/does-not-exist'), isNull);
    });
  });
}
