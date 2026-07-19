import 'dart:async';

/// Bridges the trips realtime stream to a single debounced, non-overlapping
/// refresh. Supabase can fire a burst of row changes for one booking update, so
/// bursts collapse into one reload and a slow reload never stacks on the next.
class TripsRealtimeRefresher {
  TripsRealtimeRefresher({
    required Stream<void> Function() watch,
    required Future<void> Function() onChange,
  }) : _watch = watch,
       _onChange = onChange;

  final Stream<void> Function() _watch;
  final Future<void> Function() _onChange;

  StreamSubscription<void>? _subscription;
  Timer? _debounce;
  bool _running = false;

  /// Starts listening once; further calls are no-ops.
  void start() {
    if (_subscription != null) return;
    _subscription = _watch().listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _fire);
    }, onError: (_) {});
  }

  Future<void> _fire() async {
    if (_running) return;
    _running = true;
    try {
      await _onChange();
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
  }
}
