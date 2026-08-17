/// The vocabulary for *how well a live position feed is running* — shared by
/// every surface that watches one.
///
/// These two enums started inside the client's tracking feature, where they were
/// correct but unreachable: the dashboard watches the same table, fed by the same
/// captain, over the same transport, and had no way to say the same things. A
/// second private copy would have been the start of the exact drift
/// [LiveTrackingConfig] exists to prevent — one surface calling a feed healthy
/// while another calls it stale, about the same bus, at the same moment.
///
/// They are a domain fact, not a Supabase one. Datasources map whatever their
/// transport reports onto these values, so nothing above the data layer needs to
/// know that a realtime channel exists.
library;

/// Health of the live link carrying vehicle positions.
enum TrackingLink {
  /// The feed is established and rows are expected to arrive as they happen.
  connected,

  /// The socket is not healthy, so positions are being fetched by catch-up poll
  /// instead. Still live, just coarser — the distinction the watcher deserves.
  degraded,

  /// Nothing is arriving by either path.
  lost;

  bool get isConnected => this == TrackingLink.connected;
}

/// Whether the last position can still be believed.
enum TrackingFreshness {
  live,
  stale;

  bool get isStale => this == TrackingFreshness.stale;
}
