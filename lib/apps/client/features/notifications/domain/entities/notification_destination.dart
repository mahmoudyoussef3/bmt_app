import 'client_notification.dart';

/// Where tapping a notification should take the rider, and with what arguments.
///
/// ### Why this is derived in the app rather than read off the row
///
/// `notifications.action_url` was designed to carry the destination, but no
/// backend writer populates it: `push_notification` defaults it to `null` and
/// every caller in the notification engine omits it. Measured on the live
/// database, **all 74 rows have `action_url = null`** — so before this resolver
/// every notification in the Client app was a tap that did nothing.
///
/// The rows do carry what matters: `type` says what happened, and `data` holds
/// the ids (`booking_id`, `trip_id`, `ticket_id`, `subscription_id`). Routing is
/// the app's own knowledge, not a business rule the database should own, so the
/// destination is resolved here from facts the row already has. That fixes every
/// historical row at once with no data migration, and keeps route names in one
/// place — the app — instead of duplicated as strings in SQL.
///
/// A non-empty `action_url` still wins when one appears, so the backend can
/// override a destination later without an app release.
class NotificationDestination {
  const NotificationDestination(this.route, [this.arguments]);

  final String route;
  final Object? arguments;

  @override
  bool operator ==(Object other) =>
      other is NotificationDestination &&
      other.route == route &&
      _sameArguments(other.arguments, arguments);

  @override
  int get hashCode => route.hashCode;

  static bool _sameArguments(Object? a, Object? b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((key) => a[key] == b[key]);
    }
    return a == b;
  }
}

/// Route names this resolver may produce.
///
/// Declared here rather than imported from each feature's `*Routes` class so the
/// domain layer stays free of presentation imports, matching the rest of the
/// Client App's layering. The values are asserted against the real route
/// constants in `notification_destination_test.dart`, so a rename cannot drift
/// the two apart silently.
abstract final class NotificationRoutePaths {
  static const tripDetails = '/trips/details';
  static const tracking = '/tracking';
  static const myTrips = '/trips';
  static const ticketDetails = '/ticket_details';
  static const supportCenter = '/support';
  static const mySubscription = '/my-subscription';
}

/// Resolves a notification to the screen that answers it, or `null` when there
/// is nothing useful to open.
///
/// Returning `null` is a real answer: a notification with no destination renders
/// as a plain, non-tappable entry rather than a button that silently does
/// nothing — which is what the whole inbox did before.
NotificationDestination? resolveNotificationDestination(
  ClientNotification notification,
) {
  final override = notification.actionUrl?.trim();
  if (override != null && override.isNotEmpty) {
    return NotificationDestination(override, _idArguments(notification));
  }

  final data = notification.data;
  final bookingId = _string(data['booking_id']);
  final ticketId = _string(data['ticket_id']);
  final type = notification.type.trim().toLowerCase();

  if (ticketId != null) {
    return NotificationDestination(
      NotificationRoutePaths.ticketDetails,
      ticketId,
    );
  }
  if (type.startsWith('support') || type.startsWith('refund')) {
    return const NotificationDestination(NotificationRoutePaths.supportCenter);
  }

  if (type.startsWith('subscription') || type.startsWith('package')) {
    return const NotificationDestination(NotificationRoutePaths.mySubscription);
  }

  if (bookingId != null) {
    
    if (_isTrackingEvent(type)) {
      return NotificationDestination(NotificationRoutePaths.tracking, {
        'bookingId': bookingId,
      });
    }
    return NotificationDestination(NotificationRoutePaths.tripDetails, {
      'tripId': bookingId,
    });
  }

  if (_string(data['trip_id']) != null || type.startsWith('trip')) {
    return const NotificationDestination(NotificationRoutePaths.myTrips);
  }

  return null;
}

/// Events that mean "the vehicle is moving now".
bool _isTrackingEvent(String type) =>
    type.contains('tracking') ||
    type.contains('departed') ||
    type.contains('on_way') ||
    type.contains('boarding') ||
    type == 'trip_started' ||
    type == 'trip_in_progress';

/// Arguments for a server-supplied `action_url`.
///
/// Historic rows carry a bare path with no arguments, which is how a "payment
/// approved" tap used to land on Trip Details showing *the newest booking*
/// rather than the one the notification was about (`TripsCubit._select` falls
/// back to `trips.firstOrNull` when handed a null id). Passing the row's own id
/// along removes that guess.
Object? _idArguments(ClientNotification notification) {
  final bookingId = _string(notification.data['booking_id']);
  if (bookingId != null) return {'tripId': bookingId, 'bookingId': bookingId};
  final ticketId = _string(notification.data['ticket_id']);
  if (ticketId != null) return ticketId;
  return null;
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}
