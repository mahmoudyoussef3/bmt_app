import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_seat_map.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The operator-facing behaviour: the seats tab draws the cabin of the vehicle
/// actually running the trip — a Hiace looks like a Hiace, a Coaster like a
/// Coaster — rather than a flat grid of numbered cards.

/// Seats laid out the way a vehicle of [type] stores them, so the trip's data
/// matches what the blueprint expects to pour into its slots.
List<TripSeat> _seatsFor(VehicleType type) {
  final definitions = VehicleSeatLayouts.seatDefinitionsFor(
    type,
  )!.where((d) => !d.isDriver).toList();
  return [
    for (var i = 0; i < definitions.length; i++)
      TripSeat(
        id: 'seat-$i',
        label: definitions[i].label,
        row: definitions[i].row,
        column: definitions[i].column,
        state: TripSeatState.available,
      ),
  ];
}

OperationTrip _trip({
  required String vehicleType,
  required List<TripSeat> seats,
}) {
  return OperationTrip(
    id: 'trip-1',
    routeId: 'route-1',
    route: 'بنها - القاهرة الجديدة',
    routePoints: const [],
    driverId: 'driver-1',
    driver: 'أحمد حسن',
    vehicleId: 'vehicle-1',
    vehicle: 'Hiace (BUS-1) 1234',
    vehicleType: vehicleType,
    date: '2026-07-30',
    departure: '11:00',
    arrival: '12:30',
    status: OperationTripStatus.scheduled,
    capacity: seats.length,
    seats: seats,
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

Future<void> _pump(WidgetTester tester, OperationTrip trip) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: TripSeatMap(trip: trip)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a Hiace trip draws the Hiace cabin, driver bench included', (
    tester,
  ) async {
    final seats = _seatsFor(VehicleType.hiace);
    await _pump(tester, _trip(vehicleType: 'Hiace', seats: seats));

    // Every stored seat is on the map, under its own label.
    expect(seats.length, 14);
    for (final seat in seats) {
      expect(find.text(seat.label), findsOneWidget);
    }

    // The cabin, not just the seats: the driver bench and the front/rear cues.
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('مقدمة المركبة'), findsOneWidget);
    expect(find.text('مؤخرة المركبة'), findsOneWidget);
    expect(find.textContaining('هايس'), findsOneWidget);
  });

  testWidgets('a Coaster trip draws the Coaster cabin with its door', (
    tester,
  ) async {
    final seats = _seatsFor(VehicleType.coaster);
    await _pump(tester, _trip(vehicleType: 'Coaster', seats: seats));

    expect(seats.length, VehicleSeatLayouts.coaster.capacity);
    expect(find.text('باب'), findsOneWidget);
    expect(find.textContaining('كوستر'), findsOneWidget);
    expect(find.text('${seats.length}'), findsOneWidget);
  });

  testWidgets('the cabin is drawn left-to-right under the dashboard RTL', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(vehicleType: 'Hiace', seats: _seatsFor(VehicleType.hiace)),
    );

    // Seat 1 sits beside the driver on the right of a Hiace; seat 2 opens the
    // second row on the left. Under an un-pinned RTL the bus would mirror and
    // seat 2 would land to seat 1's right.
    final one = tester.getCenter(find.text('1'));
    final two = tester.getCenter(find.text('2'));
    expect(two.dx, lessThan(one.dx));
  });

  testWidgets('a vehicle with no blueprint still shows every seat', (
    tester,
  ) async {
    final seats = [
      for (var i = 0; i < 7; i++)
        TripSeat(
          id: 'seat-$i',
          label: '${i + 1}',
          row: (i ~/ 3) + 1,
          column: (i % 3) + 1,
          state: TripSeatState.available,
        ),
    ];
    await _pump(tester, _trip(vehicleType: 'Sprinter', seats: seats));

    for (final seat in seats) {
      expect(find.text(seat.label), findsOneWidget);
    }
    expect(find.textContaining('سبرنتر'), findsOneWidget);
  });

  testWidgets('an operator-defined van gets its driver bench back', (
    tester,
  ) async {
    // The 14-seat grid `SeatConfiguration.generateDefault` produces: one seat
    // beside the driver, then 3-across rows. `trip_seats` carries no driver
    // row, so the front-left hole is the only trace of where the driver sits.
    final seats = <TripSeat>[
      const TripSeat(
        id: 'seat-1',
        label: '1',
        row: 1,
        column: 3,
        state: TripSeatState.available,
      ),
      for (var i = 1; i < 14; i++)
        TripSeat(
          id: 'seat-${i + 1}',
          label: '${i + 1}',
          row: ((i - 1) ~/ 3) + 2,
          column: ((i - 1) % 3) + 1,
          state: TripSeatState.available,
        ),
    ];
    await _pump(tester, _trip(vehicleType: 'H1', seats: seats));

    expect(find.text('سائق'), findsOneWidget);
    for (final seat in seats) {
      expect(find.text(seat.label), findsOneWidget);
    }

    // The bench sits at the front, to the left of the seat beside it.
    expect(
      tester.getCenter(find.text('سائق')).dx,
      lessThan(tester.getCenter(find.text('1')).dx),
    );
  });

  testWidgets('a cabin from a blueprint never gains a second driver bench', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(vehicleType: 'Coaster', seats: _seatsFor(VehicleType.coaster)),
    );

    // The Coaster blueprint labels its own bench 'A1'; the derived-grid rule
    // must not fire on top of it.
    expect(find.text('سائق'), findsNothing);
    expect(find.text('A1'), findsOneWidget);
  });

  testWidgets('a seat count that disagrees with the type is drawn and named', (
    tester,
  ) async {
    // A Hiace carrying 16 seats: rather than a Hiace frame with two seats
    // hanging off it, the stored grid is drawn — and the caption says why.
    final seats = [
      ..._seatsFor(VehicleType.hiace),
      const TripSeat(
        id: 'seat-extra-1',
        label: '15',
        row: 6,
        column: 1,
        state: TripSeatState.available,
      ),
      const TripSeat(
        id: 'seat-extra-2',
        label: '16',
        row: 6,
        column: 2,
        state: TripSeatState.blocked,
      ),
    ];
    await _pump(tester, _trip(vehicleType: 'Hiace', seats: seats));

    expect(find.text('15'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.textContaining('لا يطابق تخطيط النوع'), findsOneWidget);
  });

  testWidgets('seats sharing a coordinate are listed, never dropped', (
    tester,
  ) async {
    // Two seats on the same (row, column) collapse into one cabin slot. The
    // second one is still bookable inventory, so it is listed outside the bus.
    const seats = [
      TripSeat(
        id: 's-1',
        label: '1',
        row: 1,
        column: 1,
        state: TripSeatState.available,
      ),
      TripSeat(
        id: 's-2',
        label: '2',
        row: 1,
        column: 2,
        state: TripSeatState.paid,
      ),
      TripSeat(
        id: 's-3',
        label: '3',
        row: 1,
        column: 2,
        state: TripSeatState.blocked,
      ),
    ];
    await _pump(tester, _trip(vehicleType: 'Sprinter', seats: seats));

    for (final seat in seats) {
      expect(find.text(seat.label), findsOneWidget);
    }
    expect(find.textContaining('مقاعد إضافية'), findsOneWidget);
  });
}
