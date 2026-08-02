import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/network/captain_connectivity_watcher.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_connectivity_banner.dart';

/// The captain's offline banner used to be driven straight off
/// `connectivity_plus`, which reports interfaces rather than reachability and
/// only ever emits on *change*. A single wrong `none` — Android hands the
/// default network from Wi-Fi to mobile, iOS answers a cold read from
/// `NWPathMonitor` before its first path update — was therefore never
/// corrected, and the trip screen told an online captain they had no internet
/// for the rest of the trip.
///
/// These tests pin the two properties that fix it: the interface reading never
/// decides anything on its own, and no verdict can latch.
void main() {
  const settle = Duration(milliseconds: 120);

  CaptainConnectivityWatcher build({
    required ReachabilityProbe probe,
    Stream<List<ConnectivityResult>>? interfaceChanges,
  }) {
    return CaptainConnectivityWatcher(
      probe: probe,
      interfaceChanges: interfaceChanges ?? const Stream.empty(),
      confirmDelay: const Duration(milliseconds: 5),
      offlineRecheck: const Duration(milliseconds: 20),
      onlineRecheck: const Duration(milliseconds: 20),
    );
  }

  test('an interface reporting "none" is not offline while the backend is '
      'still reachable', () async {
    final interface = StreamController<List<ConnectivityResult>>();
    addTearDown(interface.close);
    final watcher = build(
      probe: () async => true,
      interfaceChanges: interface.stream,
    );
    addTearDown(watcher.dispose);

    watcher.start();
    interface.add([ConnectivityResult.none]);
    await Future<void>.delayed(settle);

    expect(watcher.value, isFalse);
  });

  test('one failed probe is not an outage', () async {
    var failuresLeft = 1;
    final watcher = build(
      probe: () async {
        if (failuresLeft > 0) {
          failuresLeft--;
          return false;
        }
        return true;
      },
    );
    addTearDown(watcher.dispose);

    watcher.start();
    await Future<void>.delayed(settle);

    expect(watcher.value, isFalse);
    expect(failuresLeft, 0, reason: 'the failing probe should have been used');
  });

  test('a confirmed outage shows, then clears on its own once the backend '
      'answers again — with no connectivity event to prompt it', () async {
    var reachable = false;
    final watcher = build(probe: () async => reachable);
    addTearDown(watcher.dispose);

    watcher.start();
    await Future<void>.delayed(settle);
    expect(watcher.value, isTrue);

    reachable = true;
    await Future<void>.delayed(settle);
    expect(
      watcher.value,
      isFalse,
      reason: 'the offline verdict must not be able to latch',
    );
  });

  test('recheck supersedes an evaluation still in flight', () async {
    var reachable = false;
    final watcher = build(probe: () async => reachable);
    addTearDown(watcher.dispose);

    watcher.start();
    reachable = true;
    watcher.recheck();
    await Future<void>.delayed(settle);

    expect(watcher.value, isFalse);
  });

  testWidgets('the banner renders only on a confirmed outage', (tester) async {
    final watcher = CaptainConnectivityWatcher(
      probe: () async => true,
      interfaceChanges: const Stream.empty(),
    );
    addTearDown(watcher.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: CaptainConnectivityBanner(watcher: watcher)),
        ),
      ),
    );

    expect(find.text('لا يوجد اتصال بالإنترنت حالياً'), findsNothing);

    watcher.value = true;
    await tester.pump();
    expect(find.text('لا يوجد اتصال بالإنترنت حالياً'), findsOneWidget);

    watcher.value = false;
    await tester.pump();
    expect(find.text('لا يوجد اتصال بالإنترنت حالياً'), findsNothing);
  });
}
