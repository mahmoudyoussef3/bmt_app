import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/services/pickup_planner.dart';

void main() {
  final stops = [
    _stop('s0', 'محطة مصر', 31.20, 29.90),
    _stop('s1', 'سيدي جابر', 31.22, 29.94),
    _stop('s2', 'المنتزه', 31.28, 30.01),
  ];

  test('groups riders under their boarding stop, in route order', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'سيدي جابر', PassengerBoardingStatus.pending),
        _rider('p2', 'محطة مصر', PassengerBoardingStatus.pending),
        _rider('p3', 'سيدي جابر', PassengerBoardingStatus.pending),
      ],
    );

    // Two boarding stops, ordered by their route position — not by the order
    // the riders happen to appear in the manifest.
    expect(plan.stops.map((s) => s.name), ['محطة مصر', 'سيدي جابر']);
    expect(plan.stops[1].total, 2);
    expect(plan.stops.first.stopIndex, 0);
  });

  test('the active pickup is the first stop with a pending rider', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'محطة مصر', PassengerBoardingStatus.boarded),
        _rider('p2', 'سيدي جابر', PassengerBoardingStatus.pending),
      ],
    );

    // The first stop is fully boarded, so the sequence has already advanced.
    expect(plan.active?.name, 'سيدي جابر');
    expect(plan.upcoming, isNull);
  });

  test('resolving the last pending rider promotes the next stop automatically',
      () {
    final passengers = [
      _rider('p1', 'محطة مصر', PassengerBoardingStatus.pending),
      _rider('p2', 'سيدي جابر', PassengerBoardingStatus.pending),
    ];

    final before = PickupPlanner.plan(stops: stops, passengers: passengers);
    expect(before.active?.name, 'محطة مصر');

    // Board the only rider at the first stop — no manual "next" selection.
    passengers[0] = _rider('p1', 'محطة مصر', PassengerBoardingStatus.boarded);
    final after = PickupPlanner.plan(stops: stops, passengers: passengers);

    expect(after.active?.name, 'سيدي جابر');
  });

  test('a no-show also resolves a rider and advances the pickup', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'محطة مصر', PassengerBoardingStatus.absent),
        _rider('p2', 'سيدي جابر', PassengerBoardingStatus.pending),
      ],
    );
    expect(plan.active?.name, 'سيدي جابر');
  });

  test('when every rider is resolved there is no active pickup', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'محطة مصر', PassengerBoardingStatus.boarded),
        _rider('p2', 'سيدي جابر', PassengerBoardingStatus.absent),
      ],
    );
    expect(plan.active, isNull);
    expect(plan.isAllResolved, isTrue);
    expect(plan.totalBoarded, 1);
    expect(plan.totalRiders, 2);
  });

  test('cancelled bookings are excluded and never hold a stop pending', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'محطة مصر', PassengerBoardingStatus.boarded),
        _rider('p2', 'محطة مصر', PassengerBoardingStatus.cancelled),
      ],
    );
    expect(plan.stops.single.total, 1, reason: 'cancelled rider is dropped');
    expect(plan.isAllResolved, isTrue);
  });

  test('matching ignores case and surrounding whitespace', () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', '  محطة مصر  ', PassengerBoardingStatus.pending),
      ],
    );
    expect(plan.active?.stopIndex, 0);
    expect(plan.active?.hasCoordinates, isTrue);
  });

  test('riders whose pickup matches no stop still appear, after mapped stops',
      () {
    final plan = PickupPlanner.plan(
      stops: stops,
      passengers: [
        _rider('p1', 'محطة مصر', PassengerBoardingStatus.pending),
        _rider('p2', 'نقطة غير معروفة', PassengerBoardingStatus.pending),
      ],
    );
    expect(plan.stops.map((s) => s.name), ['محطة مصر', 'نقطة غير معروفة']);
    expect(plan.stops.last.stopIndex, isNull);
    expect(plan.stops.last.hasCoordinates, isFalse);
  });
}

AssignedTripStop _stop(String id, String name, double lat, double lng) =>
    AssignedTripStop(id: id, name: name, latitude: lat, longitude: lng);

Passenger _rider(String id, String pickup, PassengerBoardingStatus status) =>
    Passenger(
      id: id,
      name: 'راكب $id',
      seat: 'A1',
      pickupPoint: pickup,
      destination: 'المنتزه',
      pickupTime: '08:00',
      phone: '01000000000',
      status: status,
    );
