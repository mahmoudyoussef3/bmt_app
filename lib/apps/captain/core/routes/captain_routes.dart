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
  static const passengerManifest = '/captain/trip/passengers';
  static const locationUpdate = '/captain/trip/location';
  static const chats = '/captain/trip/chats';
  static const chatDetails = '/captain/trip/chat';
  static const statusUpdate = '/captain/trip/status';
  static const reportIncident = '/captain/trip/incident';
}
