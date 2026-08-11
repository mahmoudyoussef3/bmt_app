sealed class LiveLocationState {
  const LiveLocationState();

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

  final String? lastError;

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
