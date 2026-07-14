import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/formatters/tracking_focus.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// A rider cares about exactly one stop at a time: before they board it is
/// *their* boarding point, and afterwards it is *their* drop-off. The old
/// screen always counted down to the end of the line, which is the wrong
/// number for every passenger who does not ride the route to its terminus.
void main() {
  group('TrackingFocus', () {
    test('counts down to the rider stop before they board', () {
      final focus = TrackingFocus.of(
        _trip(
          rider: const TrackingRider(
            boardingIndex: 1,
            dropoffIndex: 3,
            status: 'reserved',
          ),
        ),
        _progress(),
      );

      expect(focus.isBoarding, isTrue);
      expect(focus.target!.stop.name, 'Nasr City');
    });

    test('switches to the drop-off once the captain checks the rider in', () {
      final focus = TrackingFocus.of(
        _trip(
          rider: const TrackingRider(
            boardingIndex: 1,
            dropoffIndex: 3,
            status: 'confirmed', // boarded
          ),
        ),
        _progress(),
      );

      expect(focus.isBoarding, isFalse);
      expect(focus.target!.stop.name, 'Smart Village');
    });

    test(
      'switches to the drop-off when the bus has already passed the rider '
      'boarding stop, rather than counting down to a moment that has gone',
      () {
        final focus = TrackingFocus.of(
          _trip(
            rider: const TrackingRider(
              boardingIndex: 1,
              dropoffIndex: 3,
              status: 'reserved',
            ),
          ),
          // The bus has departed Nasr City.
          _progress(departedUpTo: 1),
        );

        expect(focus.isBoarding, isFalse);
        expect(focus.target!.stop.name, 'Smart Village');
      },
    );

    test('falls back to the last stop when the manifest has no segment', () {
      final focus = TrackingFocus.of(
        _trip(rider: const TrackingRider()),
        _progress(),
      );

      expect(focus.isBoarding, isFalse);
      expect(focus.target!.stop.name, 'Smart Village');
    });

    test('has no target before any progress exists', () {
      final focus = TrackingFocus.of(_trip(rider: const TrackingRider()), null);

      expect(focus.hasTarget, isFalse);
      expect(focus.eta, isNull);
    });
  });
}

TrackingTripData _trip({required TrackingRider rider}) => TrackingTripData(
  tripId: 'trip-1',
  bookingId: 'booking-1',
  stops: const [],
  tripState: TrackingTripState.inProgress,
  rider: rider,
);

/// A four-stop route; [departedUpTo] stops are already behind the bus.
RouteProgressSnapshot _progress({int departedUpTo = -1}) {
  const names = ['Banha', 'Nasr City', 'Heliopolis', 'Smart Village'];
  return RouteProgressSnapshot(
    phase: TripProgressPhase.enRoute,
    hasVehicleFix: true,
    isStale: false,
    isOffRoute: false,
    routeFraction: 0.3,
    traveledMeters: 3000,
    totalRouteMeters: 10000,
    nextStopIndex: departedUpTo + 1,
    stops: [
      for (final (i, name) in names.indexed)
        StopProgress(
          stop: RouteStop(
            name: name,
            latitude: 30.0 + i,
            longitude: 31.0,
            order: i,
          ),
          status: i <= departedUpTo
              ? StopVisitStatus.departed
              : (i == departedUpTo + 1
                    ? StopVisitStatus.next
                    : StopVisitStatus.upcoming),
          eta: DateTime(2026, 7, 15, 9, i * 15),
          etaConfidence: EtaConfidence.live,
        ),
    ],
  );
}
