/// The outcome of checking whether the device can produce a live position,
/// resolved before the map subscribes to the position stream.
///
/// Kept separate from the fix itself so the map can say *why* it has no live
/// position — a denied permission and a phone that simply hasn't got a fix yet
/// are different things a captain needs told apart (see the GPS-health pill).
enum LocationGate {
  /// Service on and permission granted — the position stream can start.
  ready,

  /// The OS location service is switched off device-wide.
  serviceDisabled,

  /// Permission denied for now; asking again may still succeed.
  denied,

  /// Permission denied permanently; only the app settings can restore it.
  deniedForever,
}

extension LocationGateX on LocationGate {
  bool get isReady => this == LocationGate.ready;
}
