import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_progress_summary.dart';

import '../../client_test_app.dart';
import '../tracking/tracking_test_harness.dart';

void main() {
  late FakeTrackingDatasource datasource;
  late LiveTrackingBloc bloc;

  // Deliberately a group-level setUp/tearDown rather than an `addTearDown`
  // inside the pump helper: `Bloc.close()` completes through the bloc's own
  // internal streams, and awaiting that from inside a `testWidgets` body
  // deadlocks — that zone owns the clock, so the future it is waiting on never
  // completes and the whole file hangs with no failure reported.
  setUp(() {
    datasource = FakeTrackingDatasource(trip: const TrackingTripData.none());
    bloc = buildLiveTrackingBloc(datasource);
  });

  tearDown(() async {
    await bloc.close();
    await datasource.dispose();
  });

  /// Route progress now comes from the live feed, so the card needs the bloc in
  /// scope; [state] is consulted only for *why* there is no progress yet.
  Future<void> pump(WidgetTester tester, TrackingState state) async {
    await tester.pumpWidget(
      clientTestApp(
        BlocProvider<LiveTrackingBloc>.value(
          value: bloc,
          child: Scaffold(body: TripProgressSummary(state: state)),
        ),
      ),
    );
    await tester.pump();
  }

  group('TripProgressSummary', () {
    // The readout used to handle loading and error and then cast whatever was
    // left to TrackingLoaded. TrackingEmpty is an ordinary answer — the rider
    // has no trackable booking yet — so that cast threw and took the whole
    // trip-details list down with it, leaving the screen as a bare app bar.
    testWidgets('renders a hint instead of throwing when tracking is empty', (
      tester,
    ) async {
      await pump(tester, const TrackingEmpty());

      expect(tester.takeException(), isNull);
      expect(find.byType(TripProgressSummary), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('every tracking state renders without throwing', (
      tester,
    ) async {
      for (final state in const <TrackingState>[
        TrackingLoading(),
        TrackingEmpty(),
        TrackingError('offline'),
      ]) {
        await pump(tester, state);
        expect(
          tester.takeException(),
          isNull,
          reason: '$state must degrade to a hint, never crash the card',
        );
      }
    });

    testWidgets('a loaded state with no vehicle fix still only hints', (
      tester,
    ) async {
      await pump(
        tester,
        const TrackingLoaded(data: TrackingTripData.none()),
      );

      expect(tester.takeException(), isNull);
      // No percentage is invented when the engine has no fix to report.
      expect(find.textContaining('%'), findsNothing);
    });
  });
}
