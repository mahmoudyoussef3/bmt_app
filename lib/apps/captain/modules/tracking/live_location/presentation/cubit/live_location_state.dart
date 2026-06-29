sealed class LiveLocationState {
  const LiveLocationState();
}

class LiveLocationReady extends LiveLocationState {
  const LiveLocationReady({this.enabled = false});

  final bool enabled;
}

class LiveLocationLoading extends LiveLocationState {
  const LiveLocationLoading();
}

class LiveLocationError extends LiveLocationState {
  const LiveLocationError(this.message);

  final String message;
}
