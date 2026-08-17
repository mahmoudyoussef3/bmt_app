import 'tracking_config.dart';

/// The one place the live tracking pipeline's cadences live — the captain's
/// publishing rate and the client's freshness threshold, side by side.
///
/// They belong in the same object because they are two halves of one promise:
/// the producer says how often it will report, and the consumer says how long it
/// will keep believing the last report. Splitting them across two features is
/// how a publisher slows down and nothing notices that "live" started meaning
/// something else.
class LiveTrackingConfig {
  const LiveTrackingConfig({
    this.publishInterval = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.distanceFilterMeters = 10,
    this.minimumAccuracyMeters = TrackingConfig.defaultMaxAccuracyMeters,
    this.staleAfter = const Duration(seconds: 45),
    this.reconnectPollInterval = const Duration(seconds: 8),
    this.etaRefreshInterval = const Duration(seconds: 30),
  });

  /// Floor on the gap between two published fixes — the throttle window.
  ///
  /// 10 s is derived from this app's own numbers, not from taste:
  ///
  /// * [TrackingConfig.maxAnimation] is 6 s, which is the marker engine stating
  ///   what "live" looks like: a gap of 6 s or less renders as continuous
  ///   motion. At the previous 30 s cadence the marker glided for 6 s and then
  ///   sat frozen for 24 — a slideshow, not a live map.
  /// * A bus at 80 km/h (22 m/s) crosses the 300 m diameter of a stop's
  ///   `arrivalRadiusMeters` in 13.5 s, so at 30 s it could enter and leave a
  ///   station's radius entirely between two fixes. That is why
  ///   `passedStopSlackMeters` and the "rolled past without a detected dwell"
  ///   branch exist — they are compensators for a cadence too coarse to observe
  ///   an arrival. At 10 s the bus covers 222 m per window and lands a fix
  ///   inside the radius, which makes arrival observed rather than inferred.
  ///
  /// Not lower, because below 10 s the added fidelity is invisible to someone
  /// watching a bus on a 40 km corridor while the write volume and the GPS duty
  /// cycle keep climbing linearly.
  final Duration publishInterval;

  /// How long the GPS stream may stay silent before the publisher takes a fix
  /// on its own.
  ///
  /// [distanceFilterMeters] means a stationary vehicle produces no stream
  /// events at all, so without this a parked bus would stop reporting and read
  /// as a tracking failure rather than as a bus that is parked. Deliberately
  /// equal to the pre-stream publishing cadence: the heartbeat is exactly the
  /// old behaviour, kept as the floor, with movement-driven fixes layered on
  /// top. A moving vehicle never reaches it.
  final Duration heartbeatInterval;

  /// Minimum movement before the device reports a new position. Suppresses the
  /// standing-still jitter that would otherwise spend a write to say nothing.
  final double distanceFilterMeters;

  /// Fixes with a worse (larger) reported accuracy are never published.
  ///
  /// Shares [TrackingConfig.defaultMaxAccuracyMeters] rather than restating it,
  /// so the producer cannot come to disagree with the consumer about what a
  /// usable fix is — a fix the client would reject is a write, a WAL row and a
  /// realtime fan-out spent on a position nobody will draw.
  final double minimumAccuracyMeters;

  /// Without a fix landing for this long the client feed is flagged stale.
  ///
  /// An independent constant, and deliberately **not** a multiple of
  /// [publishInterval] the way the captain's own `kLocationStaleAfter` is. At
  /// three intervals this would be 30 s, so one tunnel or one traffic-light
  /// shadow would announce a tracking failure. Staleness is a claim about
  /// whether the rider should still trust the dot, which is a different question
  /// from how often the bus reports.
  final Duration staleAfter;

  /// Cadence of the catch-up poll, which runs **only** while the realtime link
  /// is not healthy. While the socket is connected there are no periodic
  /// queries at all.
  final Duration reconnectPollInterval;

  /// How often a standing ETA is re-counted.
  ///
  /// An ETA is a moment in time, so it decays on its own even when no new fix
  /// arrives — "12 minutes away" has to become "11 minutes away" without the bus
  /// doing anything. Touches no network: it re-reads the progress engine.
  ///
  /// Kept separate from [staleAfter] so freshness can be checked more often than
  /// ETAs are redrawn; a stale feed is worth noticing sooner than a minute-hand
  /// tick is worth repainting.
  final Duration etaRefreshInterval;
}

/// The shared default. Every surface reads this unless a test overrides it.
const LiveTrackingConfig kLiveTrackingConfig = LiveTrackingConfig();
