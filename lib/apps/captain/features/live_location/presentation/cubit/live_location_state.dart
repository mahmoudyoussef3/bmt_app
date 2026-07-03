sealed class LiveLocationState {
  const LiveLocationState();
}

class LiveLocationReady extends LiveLocationState {
  const LiveLocationReady({this.lastSentAt});

  final DateTime? lastSentAt;
}

class LiveLocationLoading extends LiveLocationState {
  const LiveLocationLoading();
}

class LiveLocationError extends LiveLocationState {
  const LiveLocationError(this.message);

  final String message;
}
