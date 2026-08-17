import 'dart:async';

/// Rate-limits a stream to at most one event per [window], **keeping the newest
/// value** rather than the oldest.
///
/// ## Why throttle and not debounce
///
/// Debounce publishes only after the input goes quiet. A vehicle in motion emits
/// GPS fixes continuously, so the quiet period never arrives and a debounced
/// publisher would **never publish while the bus was moving** — it would report
/// only once the vehicle stopped. That is the requirement exactly inverted: the
/// feed would go silent precisely while passengers were watching it, and wake up
/// when there was nothing to see.
///
/// Debounce answers "the input has settled, act now", which is a search box.
/// Tracking asks "the input never settles, report at a bounded rate", which is
/// a throttle.
///
/// ## Shape: leading edge, then trailing latest
///
/// ```
/// in:   A(0s) B(1s) C(2s) … J(9s) │ K(10s) L(11s) …
///                                 │
/// out:  A ─────────────────────────▶ J          (the newest, not the oldest)
///       ^ fires at once            ^ trailing edge flushes the freshest value
/// ```
///
/// The leading edge matters: the first fix after departure reaches the
/// passenger's map immediately instead of waiting out a window. Everything that
/// arrives while the window is open **replaces** the pending value, so the fix
/// that is finally published is the most recent one known — never a position the
/// vehicle has already left.
///
/// A sparse source is unaffected: once a window closes with nothing pending, the
/// next event is again a leading edge and passes straight through.
///
/// Cleanup is total — the pending timer is cancelled on unsubscribe, no value is
/// emitted after the source completes beyond the final trailing flush, and no
/// timer is ever armed once the source is done.
class LatestValueThrottle<T> extends StreamTransformerBase<T, T> {
  const LatestValueThrottle(this.window);

  final Duration window;

  @override
  Stream<T> bind(Stream<T> source) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    // Held separately from a null check so a nullable T can still be throttled.
    T? pending;
    var hasPending = false;
    var sourceDone = false;

    void closeIfDrained() {
      if (!sourceDone || hasPending || controller.isClosed) return;
      // The leading edge arms a window even when nothing follows it. Left alone
      // it would outlive the stream by up to one interval — a timer ticking for a
      // trip that has ended.
      timer?.cancel();
      timer = null;
      controller.close();
    }

    void onWindowEnd() {
      timer = null;
      if (hasPending) {
        final value = pending as T;
        pending = null;
        hasPending = false;
        if (!controller.isClosed) controller.add(value);
        // Re-arm, or a source producing faster than the window could emit twice
        // inside one interval. Never re-arm past the end of the source — that is
        // how a throttle leaks a timer into the next screen.
        if (!sourceDone) timer = Timer(window, onWindowEnd);
      }
      closeIfDrained();
    }

    void onData(T value) {
      if (timer == null) {
        if (!controller.isClosed) controller.add(value);
        timer = Timer(window, onWindowEnd);
        return;
      }
      pending = value;
      hasPending = true;
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = source.listen(
          onData,
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
          onDone: () {
            sourceDone = true;
            // Deferred out of the source's own done delivery. Closing a
            // controller from inside an event that is still firing is a sharp
            // edge — the close is accepted but the done event can fail to reach
            // the listener at all, so a caller awaiting the stream waits forever.
            scheduleMicrotask(closeIfDrained);
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        timer?.cancel();
        timer = null;
        final active = subscription;
        subscription = null;
        return active?.cancel();
      },
    );

    return controller.stream;
  }
}
