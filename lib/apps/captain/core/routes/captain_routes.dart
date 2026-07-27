/// Captain route names.
///
/// Pure constants with no imports, matching `ClientRoutes` / `DashboardRoutes`:
/// a widget can name a destination without importing the screen behind it.
/// The mapping from a name to a screen lives in `CaptainAppRouter`, and the
/// typed arguments each route expects live in `captain_route_args.dart`.
class CaptainRoutes {
  const CaptainRoutes._();

  /// The operational shell (اليوم / السجل / حسابي).
  static const home = '/captain/home';

  static const requestAccess = '/captain/request-access';
  static const notifications = '/captain/notifications';
  static const tripHistoryDetail = '/captain/history/detail';

  // Trip-scoped routes. Every one of these needs at least a trip id.
  static const tripExecution = '/captain/trip';
  static const tripMap = '/captain/trip/map';
  static const passengerManifest = '/captain/trip/passengers';
  static const locationUpdate = '/captain/trip/location';
  static const chats = '/captain/trip/chats';
  static const chatDetails = '/captain/trip/chat';
  static const statusUpdate = '/captain/trip/status';
  static const reportIncident = '/captain/trip/incident';

  /// A path the backend writes into `notifications.action_url` that does not
  /// match any route name above.
  ///
  /// `on_operation_trip_change` stamps `'/trips'` on the captain's
  /// "تم إسنادك لرحلة جديدة" notification — the most frequent push a captain
  /// receives. Tapping a push makes `FcmService` call
  /// `pushNamed(action_url)` verbatim, so the unmapped value reached
  /// `CaptainAppRouter.generateRoute`, which returned null, and Flutter threw
  /// "Could not find a generator for route". The captain's most common
  /// notification was therefore also the one that broke the app.
  ///
  /// Resolved here rather than by rewriting the trigger, because rows already
  /// carrying this string exist. `ClientRoutes` handles its own equivalents the
  /// same way (`_serverAliases`).
  static const assignmentAlias = '/trips';
}
