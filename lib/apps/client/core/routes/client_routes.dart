/// App-shell routes for the Client App.
///
/// Feature-owned routes live with their feature (`AuthRoutes`, `BookingRoutes`,
/// `TripsRoutes`, `SupportRoutes`, …); this holds only what belongs to no single
/// feature. Every path is declared exactly once across those files — a second
/// registry for the same path is what let `/booking/search` and `/trips` drift
/// under two names, so don't reintroduce one, and never register or navigate
/// with a raw string.
class ClientRoutes {
  const ClientRoutes._();

  /// The authenticated shell that hosts the bottom navigation.
  static const home = '/home';

  static const terms = '/legal/terms';
  static const privacy = '/legal/privacy';
}
