sealed class LiveLocationState {
  const LiveLocationState();

  /// Whether the periodic automatic reporting is running. Carried on every
  /// state so the UI's toggle never flickers off while a manual send resolves.
  bool get isAutoSharing;
}

class LiveLocationReady extends LiveLocationState {
  const LiveLocationReady({
    this.lastSentAt,
    this.isAutoSharing = false,
    this.lastError,
    this.consecutiveFailures = 0,
  });

  final DateTime? lastSentAt;

  @override
  final bool isAutoSharing;

  /// Why the most recent *automatic* send failed, if it did. Reported inline
  /// beside the last good fix rather than as an error state — the captain is
  /// driving, and a dropped tick is not something to interrupt them over.
  final String? lastError;

  /// How many automatic sends have failed in a row since the last one that
  /// landed. Reset to zero by any success.
  ///
  /// One failure is a pothole in the signal and is not worth a word. A run of
  /// them is a different fact — the client's map has been frozen for
  /// `consecutiveFailures × 30s` and the captain is the only person who can do
  /// anything about it — and the card says so once the run is long enough to
  /// mean something.
  final int consecutiveFailures;
}

class LiveLocationLoading extends LiveLocationState {
  const LiveLocationLoading({this.isAutoSharing = false});

  @override
  final bool isAutoSharing;
}

class LiveLocationError extends LiveLocationState {
  const LiveLocationError(this.message, {this.isAutoSharing = false});

  final String message;

  @override
  final bool isAutoSharing;
}
