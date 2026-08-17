import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/formatters/tracking_labels.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/live_progress_builder.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_signal_pill.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import 'tracking_test_harness.dart';

/// What the rider actually sees, and — just as load-bearing — what they do not
/// see repaint. A position lands every few seconds; almost nothing on the screen
/// is about the vehicle.
void main() {
  late FakeTrackingDatasource datasource;
  late LiveTrackingBloc bloc;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 8, 17, 9);
    datasource = FakeTrackingDatasource(
      trip: _trip(state: TrackingTripState.inProgress),
    );
    bloc = buildLiveTrackingBloc(datasource, now: () => now);
  });

  tearDown(() async {
    await bloc.close();
    await datasource.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<LiveTrackingBloc>.value(
          value: bloc,
          child: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  /// A single `pump` renders a frame but does not drain the microtasks that
  /// carry an event through its transformer into a handler, and a bare
  /// `Future.delayed` inside `testWidgets` never completes — the binding owns the
  /// clock, so the timer behind it is never fired. `runAsync` steps out into the
  /// real zone, which is where these stream deliveries actually live.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  Future<void> startTracking(WidgetTester tester) async {
    bloc.add(TrackingRequested(datasource.trip));
    await settle(tester);
  }

  /// A position **on** the route, walking the Nasr City → Smart Village leg.
  ///
  /// Off-route matters here: the progress engine flags a fix more than
  /// `offRouteMeters` from the polyline, and the pill reports that instead of
  /// "Live" — correctly. A test that wants to read the live label has to put the
  /// bus on the road.
  Future<void> emitFix(WidgetTester tester, {required int atSecond}) async {
    final along = atSecond * 0.0005;
    datasource.emitFix(
      latitude: 30.06 + along * (30.07 - 30.06),
      longitude: 31.34 + along * (31.01 - 31.34),
      recordedAt: now.add(Duration(seconds: atSecond)),
      speed: 12,
    );
    await settle(tester);
  }

  group('the signal pill', () {
    Widget pill() => Builder(
      builder: (context) => BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
        builder: (context, live) => TrackingSignalPill(
          progress: live.progress,
          recordedAt: live is LiveTrackingActive ? live.fix.recordedAt : null,
          freshness: live is LiveTrackingActive ? live.freshness : null,
          link: live is LiveTrackingActive ? live.link : null,
          labels: TrackingLabels(AppLocalizations.of(context)!, 'en'),
        ),
      ),
    );

    testWidgets('waits for the captain before any position', (tester) async {
      await pump(tester, pill());
      await startTracking(tester);

      expect(find.text("Waiting for the captain's signal"), findsOneWidget);
    });

    testWidgets('reads live on a fresh position', (tester) async {
      await pump(tester, pill());
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);

      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('says the signal is delayed once it goes stale', (tester) async {
      await pump(tester, pill());
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);

      now = now.add(const Duration(seconds: 60));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle(tester);

      expect(find.text('Signal delayed'), findsOneWidget);
      expect(
        find.text('Live'),
        findsNothing,
        reason: 'a frozen marker must never be presented as a live one',
      );
    });

    testWidgets('names reconnecting while the socket is down but the fix is '
        'still fresh', (tester) async {
      await pump(tester, pill());
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);

      datasource.emitLink(TrackingLink.degraded);
      await settle(tester);

      expect(find.text('Reconnecting'), findsOneWidget);
      expect(find.text('Signal delayed'), findsNothing);
    });

    testWidgets('a stale fix outranks a reconnecting socket', (tester) async {
      await pump(tester, pill());
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);
      datasource.emitLink(TrackingLink.lost);
      await settle(tester);

      now = now.add(const Duration(seconds: 60));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle(tester);

      expect(
        find.text('Signal delayed'),
        findsOneWidget,
        reason:
            'the rider needs the worse news: the position itself can no longer '
            'be trusted, which matters more than why',
      );
    });
  });

  group('rebuild boundaries', () {
    testWidgets('a position rebuilds the live section and nothing else', (
      tester,
    ) async {
      final liveBuilds = _Counter();
      final staticBuilds = _Counter();

      await pump(
        tester,
        Column(
          children: [
            LiveProgressBuilder(
              builder: (context, progress) {
                liveBuilds.value++;
                return Text('covered ${progress?.routeFraction ?? 0}');
              },
            ),
            // Stands in for the crew card, the booking card, the seat and the
            // sheet chrome — all facts about the trip, none about the vehicle.
            _CountingBox(counter: staticBuilds),
          ],
        ),
      );
      await startTracking(tester);

      final liveAfterStart = liveBuilds.value;
      final staticAfterStart = staticBuilds.value;

      for (var second = 0; second < 5; second++) {
        await emitFix(tester, atSecond: second * 10);
      }

      expect(
        liveBuilds.value,
        greaterThan(liveAfterStart),
        reason: 'the live section must follow the vehicle',
      );
      expect(
        staticBuilds.value,
        staticAfterStart,
        reason:
            'five positions must not repaint the booking details, the crew or '
            'the action buttons — that is the whole point of the split',
      );
    });

    testWidgets('a link-only change does not rebuild the progress section', (
      tester,
    ) async {
      final liveBuilds = _Counter();

      await pump(
        tester,
        LiveProgressBuilder(
          builder: (context, progress) {
            liveBuilds.value++;
            return Text('covered ${progress?.routeFraction ?? 0}');
          },
        ),
      );
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);
      final before = liveBuilds.value;

      datasource.emitLink(TrackingLink.degraded);
      await settle(tester);
      datasource.emitLink(TrackingLink.connected);
      await settle(tester);

      expect(
        liveBuilds.value,
        before,
        reason:
            'the selector sees the same snapshot object, so a flapping socket '
            'cannot repaint the stops list',
      );
    });

    testWidgets('a freshness tick that learned nothing repaints nothing', (
      tester,
    ) async {
      final liveBuilds = _Counter();

      await pump(
        tester,
        LiveProgressBuilder(
          builder: (context, progress) {
            liveBuilds.value++;
            return Text('covered ${progress?.routeFraction ?? 0}');
          },
        ),
      );
      await startTracking(tester);
      await emitFix(tester, atSecond: 0);
      final before = liveBuilds.value;

      now = now.add(const Duration(seconds: 5));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle(tester);

      expect(liveBuilds.value, before);
    });
  });

  group('states the rider can be left in', () {
    testWidgets('a boarded rider keeps their route but loses the marker', (
      tester,
    ) async {
      datasource.trip = _trip(
        state: TrackingTripState.inProgress,
        rider: const TrackingRider(bookingStatus: 'boarded'),
      );

      await pump(
        tester,
        BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
          builder: (context, live) => Text(
            live is LiveTrackingUnavailable
                ? 'no marker, stops: ${live.progress?.stops.length ?? 0}'
                : 'other',
          ),
        ),
      );
      await startTracking(tester);

      expect(find.text('no marker, stops: 3'), findsOneWidget);
    });

    testWidgets('a failed feed surfaces its reason and offers a retry', (
      tester,
    ) async {
      await pump(
        tester,
        BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
          builder: (context, live) => switch (live) {
            LiveTrackingFailure(:final message, :final canRetry) => Column(
              children: [
                Text(message),
                if (canRetry)
                  TextButton(
                    onPressed: () =>
                        context.read<LiveTrackingBloc>().add(
                          const TrackingRetryRequested(),
                        ),
                    child: const Text('Try again'),
                  ),
              ],
            ),
            _ => const Text('tracking'),
          },
        ),
      );
      await startTracking(tester);

      datasource.feed.addError(Exception('socket died'));
      await settle(tester);

      expect(find.text('socket died'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await settle(tester);

      expect(datasource.feedSubscriptions, 2);
    });
  });
}

class _Counter {
  int value = 0;
}

/// A widget that records every time it is rebuilt.
class _CountingBox extends StatelessWidget {
  const _CountingBox({required this.counter});

  final _Counter counter;

  @override
  Widget build(BuildContext context) {
    counter.value++;
    return const SizedBox(height: 8);
  }
}

TrackingTripData _trip({
  required TrackingTripState state,
  TrackingRider rider = const TrackingRider(bookingStatus: 'confirmed'),
}) {
  return TrackingTripData(
    tripId: 'trip-1',
    bookingId: 'booking-1',
    tripState: state,
    rider: rider,
    stops: const [
      RouteStop(name: 'Banha', latitude: 30.46, longitude: 31.18, order: 0),
      RouteStop(name: 'Nasr City', latitude: 30.06, longitude: 31.34, order: 1),
      RouteStop(name: 'Smart Village', latitude: 30.07, longitude: 31.01, order: 2),
    ],
  );
}
