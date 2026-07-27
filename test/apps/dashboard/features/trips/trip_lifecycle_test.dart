import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';

/// The Dart mirror of `public.update_trip_status`.
///
/// The database is the authority — a direct table write raises
/// `trip_status_direct_update_forbidden` since migration 20260727160000 — so these
/// tests are about the dashboard *offering* the right actions. They are the Dart half
/// of `supabase/tests/trip_lifecycle_regression.sql`, which asserts the same matrix
/// against the real database.
void main() {
  const all = OperationTripStatus.values;

  // The full matrix, written out rather than derived, so a change to the table has to
  // be made here too — deliberately, and next to the server's own list.
  const expectedEdges = <OperationTripStatus, Set<OperationTripStatus>>{
    OperationTripStatus.scheduled: {
      OperationTripStatus.openForBooking,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.openForBooking: {
      OperationTripStatus.boarding,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.boarding: {
      OperationTripStatus.inProgress,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.inProgress: {
      OperationTripStatus.completed,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.completed: <OperationTripStatus>{},
    OperationTripStatus.cancelled: <OperationTripStatus>{},
  };

  group('TripLifecycle transition matrix', () {
    for (final from in all) {
      for (final to in all) {
        final allowed = expectedEdges[from]!.contains(to);
        test('${from.name} -> ${to.name} is ${allowed ? "allowed" : "refused"}', () {
          expect(TripLifecycle.canTransition(from, to), allowed);
        });
      }
    }

    test('completed and cancelled are terminal', () {
      expect(TripLifecycle.isTerminal(OperationTripStatus.completed), isTrue);
      expect(TripLifecycle.isTerminal(OperationTripStatus.cancelled), isTrue);
      for (final s in all.where((s) => expectedEdges[s]!.isNotEmpty)) {
        expect(TripLifecycle.isTerminal(s), isFalse, reason: s.name);
      }
    });

    test('a terminal trip can never return to a bookable state', () {
      for (final terminal in [
        OperationTripStatus.completed,
        OperationTripStatus.cancelled,
      ]) {
        expect(
          TripLifecycle.canTransition(
            terminal,
            OperationTripStatus.openForBooking,
          ),
          isFalse,
        );
        expect(TripLifecycle.nextStatesFrom(terminal), isEmpty);
      }
    });

    test('publishing cannot be undone', () {
      expect(
        TripLifecycle.canTransition(
          OperationTripStatus.openForBooking,
          OperationTripStatus.scheduled,
        ),
        isFalse,
      );
    });

    test('every forward step is itself a legal transition', () {
      for (final from in all) {
        final next = TripLifecycle.nextStep(from);
        if (next == null) {
          expect(TripLifecycle.isTerminal(from), isTrue, reason: from.name);
          continue;
        }
        expect(
          TripLifecycle.canTransition(from, next),
          isTrue,
          reason: '${from.name} -> ${next.name}',
        );
      }
    });

    test('cancelling a live trip demands a reason', () {
      expect(
        TripLifecycle.cancellationNeedsReason(OperationTripStatus.boarding),
        isTrue,
      );
      expect(
        TripLifecycle.cancellationNeedsReason(OperationTripStatus.inProgress),
        isTrue,
      );
      expect(
        TripLifecycle.cancellationNeedsReason(OperationTripStatus.scheduled),
        isFalse,
      );
      expect(
        TripLifecycle.cancellationNeedsReason(
          OperationTripStatus.openForBooking,
        ),
        isFalse,
      );
    });
  });

  group('TripLifecycle.canDelete', () {
    test('an unpublished trip with no passengers can be deleted', () {
      expect(TripLifecycle.canDelete(_trip()), isTrue);
    });

    test('a published trip cannot be deleted', () {
      for (final status in all.where(
        (s) => s != OperationTripStatus.scheduled,
      )) {
        expect(
          TripLifecycle.canDelete(_trip(status: status)),
          isFalse,
          reason: status.name,
        );
      }
    });

    test('a trip carrying passengers cannot be deleted', () {
      expect(TripLifecycle.canDelete(_trip(passengers: [_passenger()])), isFalse);
    });
  });

  group('TripPublishBlocker', () {
    test('a fully provisioned future trip is publishable', () {
      expect(TripPublishBlocker.evaluate(_publishable()), isNull);
    });

    test('a trip with no driver is blocked', () {
      expect(
        TripPublishBlocker.evaluate(_publishable().copyWith(driverId: '')),
        TripPublishBlocker.noDriver,
      );
    });

    test('a trip with no vehicle is blocked', () {
      expect(
        TripPublishBlocker.evaluate(_publishable().copyWith(vehicleId: '')),
        TripPublishBlocker.noVehicle,
      );
    });

    test('a trip with no seat inventory is blocked', () {
      expect(
        TripPublishBlocker.evaluate(_publishable().copyWith(seats: const [])),
        TripPublishBlocker.noSeats,
      );
    });

    test('a trip whose departure day has passed is blocked', () {
      expect(
        TripPublishBlocker.evaluate(
          _publishable().copyWith(date: '2020-01-01'),
        ),
        TripPublishBlocker.pastDate,
      );
    });

    test('today is still publishable — only a past day is not', () {
      final today = DateTime(2026, 7, 27);
      expect(
        TripPublishBlocker.evaluate(
          _publishable().copyWith(date: '2026-07-27'),
          now: today,
        ),
        isNull,
      );
      expect(
        TripPublishBlocker.evaluate(
          _publishable().copyWith(date: '2026-07-26'),
          now: today,
        ),
        TripPublishBlocker.pastDate,
      );
    });

    test('every server reason code maps to an operator-facing message', () {
      for (final code in const [
        'no_driver',
        'no_vehicle',
        'no_seats',
        'no_pricing',
        'past_date',
      ]) {
        final blocker = TripPublishBlocker.fromCode(code);
        expect(blocker, isNotNull, reason: code);
        expect(blocker!.message, isNotEmpty);
      }
      expect(TripPublishBlocker.fromCode('something_else'), isNull);
    });

    test('pricing is only knowable from the server', () {
      // trip_pricing is not carried on the entity, so `no_pricing` can only arrive as
      // a server code — the local evaluation must not claim a trip is publishable-safe
      // on that axis by silently passing it.
      expect(
        TripPublishBlocker.values.contains(TripPublishBlocker.noPricing),
        isTrue,
      );
      expect(TripPublishBlocker.fromCode('no_pricing'),
          TripPublishBlocker.noPricing);
    });
  });

  group('StaleTripOutcome', () {
    test('maps to the values office_close_stale_trip accepts', () {
      expect(StaleTripOutcome.operated.dbValue, 'operated');
      expect(StaleTripOutcome.cancelled.dbValue, 'cancelled');
    });
  });

  group('OperationTripStatus wire format', () {
    test('round-trips through the database vocabulary', () {
      for (final status in all) {
        expect(
          OperationTripStatus.fromString(status.dbValue),
          status,
          reason: status.name,
        );
      }
    });

    test('matches the operation_trips_status_check values exactly', () {
      expect(
        all.map((s) => s.dbValue).toSet(),
        {
          'scheduled',
          'open_for_booking',
          'boarding',
          'in_progress',
          'completed',
          'cancelled',
        },
      );
    });
  });
}

OperationTrip _trip({
  OperationTripStatus status = OperationTripStatus.scheduled,
  List<TripPassenger> passengers = const [],
  List<TripSeat> seats = const [],
}) {
  return OperationTrip(
    id: 'trip-1',
    routeId: 'route-1',
    route: 'بنها - القرية الذكية',
    routePoints: const [],
    driverId: 'driver-1',
    driver: 'أحمد حسن',
    vehicleId: 'vehicle-1',
    vehicle: 'ق س أ 1234',
    date: '2099-01-01',
    departure: '09:00',
    arrival: '10:30',
    status: status,
    capacity: 14,
    ticketPrice: 50,
    seats: seats,
    passengers: passengers,
    events: const [],
    notes: const [],
  );
}

OperationTrip _publishable() => _trip(
  seats: const [
    TripSeat(
      id: 'seat-1',
      label: '1',
      row: 1,
      column: 1,
      state: TripSeatState.available,
    ),
  ],
);

TripPassenger _passenger() => const TripPassenger(
  id: 'pass-1',
  name: 'محمد علي',
  phone: '01000000000',
  seat: '1',
  pickup: 'بنها',
  dropoff: 'القرية الذكية',
  paymentMethod: 'instapay',
  status: 'confirmed',
);
