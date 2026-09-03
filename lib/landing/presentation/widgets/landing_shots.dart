/// The real product captures the page embeds.
///
/// Every one of these is a photograph of the shipping app, taken by
/// `tool/showcase` over invented demo data — no production row is in any of
/// them, and none of them is a drawing of a screen we wish we had. Regenerate
/// them with `node tool/showcase/capture/landing_assets.mjs` after a UI change
/// (the README next to it has the full three-command run).
///
/// The frames are *not* baked into the files: [LandingPhoneShot] and
/// [LandingBrowserShot] draw the device in Flutter, so a capture can appear at
/// any size without its chrome resampling with it.
class LandingShots {
  const LandingShots._();

  static const _dir = 'assets/showcase';

  /// Captured at 390x844 logical — the phone frames size against this.
  static const double phoneAspect = 390 / 844;

  /// Captured at 1600x1000 logical.
  static const double consoleAspect = 1600 / 1000;

  // The rider app.
  static const clientHome = '$_dir/shot-client-home.webp';
  static const clientSearch = '$_dir/shot-client-search.webp';
  static const clientSeats = '$_dir/shot-client-seats.webp';
  static const clientTrip = '$_dir/shot-client-trip.webp';

  /// Following the vehicle on a map is the rider's screen, not the captain's —
  /// the captain app has no such view, so this is the page's only map.
  static const clientTrack = '$_dir/shot-client-track.webp';
  static const clientWallet = '$_dir/shot-client-wallet.webp';

  // The captain app.
  static const captainHome = '$_dir/shot-captain-home.webp';
  static const captainTrip = '$_dir/shot-captain-trip.webp';

  // The office console.
  static const consoleOverview = '$_dir/shot-console-overview.webp';
  static const consoleHome = '$_dir/shot-console-home.webp';
  static const consoleTrips = '$_dir/shot-console-trips.webp';
  static const consoleRoutes = '$_dir/shot-console-routes.webp';
  static const consoleBookings = '$_dir/shot-console-bookings.webp';
  static const consoleFleet = '$_dir/shot-console-fleet.webp';
  static const consoleFinance = '$_dir/shot-console-finance.webp';
  static const consoleAnalytics = '$_dir/shot-console-analytics.webp';
}
