import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_progress_summary.dart';

import '../../client_test_app.dart';

Future<void> _pump(WidgetTester tester, TrackingState state) async {
  await tester.pumpWidget(
    clientTestApp(Scaffold(body: TripProgressSummary(state: state))),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TripProgressSummary', () {
    // The readout used to handle loading and error and then cast whatever was
    // left to TrackingLoaded. TrackingEmpty is an ordinary answer — the rider
    // has no trackable booking yet — so that cast threw and took the whole
    // trip-details list down with it, leaving the screen as a bare app bar.
    testWidgets('renders a hint instead of throwing when tracking is empty', (
      tester,
    ) async {
      await _pump(tester, const TrackingEmpty());

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
        await _pump(tester, state);
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
      await _pump(
        tester,
        const TrackingLoaded(data: TrackingTripData.none()),
      );

      expect(tester.takeException(), isNull);
      // No percentage is invented when the engine has no fix to report.
      expect(find.textContaining('%'), findsNothing);
    });
  });
}
