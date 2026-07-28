import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/entities/notification_destination.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/client_push_destination.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';

ClientNotification _notification({
  String type = 'general',
  Map<String, dynamic> data = const {},
  String? actionUrl,
}) {
  return ClientNotification(
    id: 'n1',
    title: 'title',
    body: 'body',
    category: NotificationCategory.fromString(type),
    type: type,
    isRead: false,
    createdAt: DateTime(2026, 7, 30),
    actionUrl: actionUrl,
    data: data,
  );
}

void main() {
  group('the resolver targets the app\'s real routes', () {
    // NotificationRoutePaths exists so the domain layer holds no presentation
    // import. These assertions are what stop the two copies drifting apart.
    test('every declared path matches its owning route constant', () {
      expect(NotificationRoutePaths.tripDetails, TripsRoutes.tripDetails);
      expect(NotificationRoutePaths.myTrips, TripsRoutes.myTrips);
      expect(NotificationRoutePaths.tracking, TrackingRoutes.tracking);
      expect(NotificationRoutePaths.ticketDetails, SupportRoutes.ticketDetails);
      expect(NotificationRoutePaths.supportCenter, SupportRoutes.center);
      expect(
        NotificationRoutePaths.mySubscription,
        PackagesRoutes.mySubscription,
      );
    });
  });

  group('a notification opens the record it is about', () {
    // Every one of the 74 notification rows in production has action_url = null,
    // so before this resolver each of these taps did nothing at all.
    test('payment approved opens that booking, not the newest one', () {
      final destination = resolveNotificationDestination(
        _notification(
          type: 'payment_approved',
          data: {'booking_id': 'booking-42', 'trip_id': 'trip-9'},
        ),
      );

      expect(destination?.route, TripsRoutes.tripDetails);
      // The id is the whole point: TripsCubit falls back to the most recent
      // booking when handed none, which is how a "payment approved" tap used to
      // open somebody's newest trip instead of the one that was approved.
      expect(destination?.arguments, {'tripId': 'booking-42'});
    });

    test('payment rejected also opens the booking, where the rider can act', () {
      final destination = resolveNotificationDestination(
        _notification(
          type: 'payment_rejected',
          data: {'booking_id': 'booking-42'},
        ),
      );

      expect(destination?.route, TripsRoutes.tripDetails);
      expect(destination?.arguments, {'tripId': 'booking-42'});
    });

    test('a departure opens the map rather than the ticket', () {
      final destination = resolveNotificationDestination(
        _notification(type: 'trip_departed', data: {'booking_id': 'booking-42'}),
      );

      expect(destination?.route, TrackingRoutes.tracking);
      expect(destination?.arguments, {'bookingId': 'booking-42'});
    });

    test('a support update opens its ticket', () {
      final destination = resolveNotificationDestination(
        _notification(type: 'support_ticket', data: {'ticket_id': 't-7'}),
      );

      expect(destination?.route, SupportRoutes.ticketDetails);
      expect(destination?.arguments, 't-7');
    });

    test('a refund update opens the support centre', () {
      final destination = resolveNotificationDestination(
        _notification(type: 'refund_request', data: {'refund_id': 'r-1'}),
      );

      expect(destination?.route, SupportRoutes.center);
    });

    test('a package expiry opens the rider\'s own subscription', () {
      final destination = resolveNotificationDestination(
        _notification(type: 'subscription', data: {'subscription_id': 's-1'}),
      );

      expect(destination?.route, PackagesRoutes.mySubscription);
    });

    test('a trip-wide announcement lands on the trip list', () {
      final destination = resolveNotificationDestination(
        _notification(type: 'trip', data: {'trip_id': 'trip-9'}),
      );

      expect(destination?.route, TripsRoutes.myTrips);
    });

    test('a notification about nothing openable resolves to nothing', () {
      expect(
        resolveNotificationDestination(_notification(type: 'announcement')),
        isNull,
      );
    });
  });

  group('a server-supplied action_url still wins', () {
    test('it is used verbatim, but carries the row\'s ids', () {
      final destination = resolveNotificationDestination(
        _notification(
          type: 'payment_approved',
          actionUrl: '/subscriptions',
          data: {'booking_id': 'booking-42'},
        ),
      );

      expect(destination?.route, '/subscriptions');
      expect(destination?.arguments, {
        'tripId': 'booking-42',
        'bookingId': 'booking-42',
      });
    });

    test('a blank action_url falls through to the derived destination', () {
      final destination = resolveNotificationDestination(
        _notification(
          type: 'payment_approved',
          actionUrl: '   ',
          data: {'booking_id': 'booking-42'},
        ),
      );

      expect(destination?.route, TripsRoutes.tripDetails);
    });
  });

  group('a tapped push lands where the tapped inbox entry does', () {
    // A push and its notifications row are written from the same event, so the
    // two must not disagree about where they open.
    test('FCM string payloads resolve identically', () {
      final destination = clientPushDestination({
        'type': 'payment_approved',
        'category': 'payment',
        'booking_id': 'booking-42',
      });

      expect(destination?.route, TripsRoutes.tripDetails);
      expect(destination?.arguments, {'tripId': 'booking-42'});
    });

    test('a payload with nothing to open resolves to nothing', () {
      expect(clientPushDestination({'type': 'announcement'}), isNull);
    });
  });
}
