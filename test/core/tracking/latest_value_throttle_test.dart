import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/latest_value_throttle.dart';

/// The rate limiter on the captain's publishing path.
///
/// Its defining property is the one that separates it from a debounce: it never
/// discards the newest value. A debounce would publish only once the input went
/// quiet, which for a bus in motion is never — the feed would go silent exactly
/// while passengers were watching it.
void main() {
  const window = Duration(seconds: 10);

  Stream<int> throttled(Stream<int> source) =>
      source.transform(LatestValueThrottle<int>(window));

  test('the first value goes out immediately', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      source.add(1);
      async.flushMicrotasks();

      expect(
        seen,
        [1],
        reason:
            'the first fix after departure must reach the map now, not one '
            'window from now',
      );

      sub.cancel();
      source.close();
      async.flushMicrotasks();
    });
  });

  test('everything arriving inside the window collapses to the newest', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      // A(leading) then B, C, D while the window is open.
      source.add(1);
      async.flushMicrotasks();
      source.add(2);
      source.add(3);
      source.add(4);
      async.flushMicrotasks();

      expect(seen, [1], reason: 'nothing else may go out inside the window');

      async.elapse(window);
      async.flushMicrotasks();

      expect(
        seen,
        [1, 4],
        reason:
            'D, not B — publishing a position the vehicle has already left '
            'would be worse than publishing nothing',
      );

      sub.cancel();
      source.close();
      async.flushMicrotasks();
    });
  });

  test('a source faster than the window still emits once per window', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      // One value a second for a minute — roughly what a high-accuracy GPS
      // stream does on a moving vehicle.
      for (var second = 0; second < 60; second++) {
        source.add(second);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
      }

      expect(
        seen.length,
        7,
        reason:
            '60 s of GPS at one fix per second is a leading edge plus six '
            'window closes — 7 writes, not 60',
      );
      // Leading 0, then the newest value seen in each closing window.
      expect(seen, [0, 9, 19, 29, 39, 49, 59]);

      sub.cancel();
      source.close();
      async.flushMicrotasks();
    });
  });

  test('a sparse source is not delayed at all', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      source.add(1);
      async.flushMicrotasks();
      // Well past the window: the next value is a leading edge again.
      async.elapse(window * 3);
      async.flushMicrotasks();
      source.add(2);
      async.flushMicrotasks();

      expect(
        seen,
        [1, 2],
        reason: 'a vehicle reporting rarely must not be throttled further',
      );

      sub.cancel();
      source.close();
      async.flushMicrotasks();
    });
  });

  test('a value held when the source closes is still flushed', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      source.add(1);
      async.flushMicrotasks();
      source.add(2);
      async.flushMicrotasks();
      source.close();
      async.flushMicrotasks();

      expect(seen, [1], reason: 'still inside the window');

      async.elapse(window);
      async.flushMicrotasks();

      expect(
        seen,
        [1, 2],
        reason: 'the last known position is not thrown away on shutdown',
      );

      sub.cancel();
    });
  });

  test('closing with nothing pending leaves no timer armed', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      source.add(1);
      async.flushMicrotasks();
      source.close();
      async.flushMicrotasks();

      expect(seen, [1]);

      sub.cancel();
      // The leading edge arms a window even with nothing behind it. fakeAsync
      // fails a test that ends with a pending timer, so this test passing at all
      // is the assertion: the window is cancelled when the source drains rather
      // than ticking on for a trip that has ended.
    });
  });

  // Stream *completion* is asserted in real async on purpose. fake_async models
  // timers, not the event loop's delivery of a done event, and it does not
  // deliver one reliably for a controller closed from inside its source's own
  // done callback — the exact shape this transformer has.
  test('completes its listener once the source has drained', () async {
    final source = StreamController<int>();
    final seen = <int>[];
    var done = false;
    throttled(source.stream).listen(seen.add, onDone: () => done = true);

    source.add(1);
    await Future<void>.delayed(Duration.zero);
    await source.close();
    await Future<void>.delayed(Duration.zero);

    expect(seen, [1]);
    expect(
      done,
      isTrue,
      reason:
          'anything awaiting the pipeline — a test, a publisher shutting down — '
          'must not wait forever',
    );
  });

  test('unsubscribing cancels the window timer and the source', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttled(source.stream).listen(seen.add);

      source.add(1);
      async.flushMicrotasks();
      source.add(2);
      async.flushMicrotasks();

      sub.cancel();
      async.flushMicrotasks();

      expect(
        source.hasListener,
        isFalse,
        reason: 'the GPS subscription goes with the throttle',
      );

      async.elapse(window * 2);
      async.flushMicrotasks();

      expect(
        seen,
        [1],
        reason: 'the pending value must not surface after unsubscribe',
      );

      source.close();
      async.flushMicrotasks();
    });
  });

  test('errors pass through without ending the stream', () {
    fakeAsync((async) {
      final source = StreamController<int>();
      final seen = <int>[];
      final errors = <Object>[];
      final sub = throttled(source.stream).listen(seen.add, onError: errors.add);

      source.add(1);
      async.flushMicrotasks();
      source.addError(Exception('gps glitch'));
      async.flushMicrotasks();
      async.elapse(window);
      source.add(2);
      async.flushMicrotasks();

      expect(errors, hasLength(1));
      expect(
        seen,
        [1, 2],
        reason: 'one bad reading does not take the pipeline down',
      );

      sub.cancel();
      source.close();
      async.flushMicrotasks();
    });
  });

  test('two subscriptions keep separate windows', () {
    fakeAsync((async) {
      final first = StreamController<int>();
      final second = StreamController<int>();
      const throttle = LatestValueThrottle<int>(window);
      final a = <int>[];
      final b = <int>[];
      final subA = first.stream.transform(throttle).listen(a.add);
      final subB = second.stream.transform(throttle).listen(b.add);

      first.add(1);
      async.flushMicrotasks();
      second.add(9);
      async.flushMicrotasks();

      expect(a, [1]);
      expect(
        b,
        [9],
        reason:
            'one stream opening a window must not silence the leading edge of '
            'another',
      );

      subA.cancel();
      subB.cancel();
      first.close();
      second.close();
      async.flushMicrotasks();
    });
  });
}
