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
  });

  final DateTime? lastSentAt;

  @override
  final bool isAutoSharing;

  /// Why the most recent *automatic* send failed, if it did. Reported inline
  /// beside the last good fix rather than as an error state — the captain is
  /// driving, and a dropped tick is not something to interrupt them over.
  final String? lastError;
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
