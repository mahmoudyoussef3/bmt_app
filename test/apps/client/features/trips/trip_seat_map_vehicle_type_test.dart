import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_map.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import '../../client_test_app.dart';

/// The client-side half of the contract: the seat map a passenger sees is the
/// cabin of the vehicle actually assigned to the trip.
List<TripSeat> _seatsFor(
  SeatLayoutBlueprint blueprint, {
  Set<int> occupied = const {},
  int? mine,
}) {
  final definitions = blueprint
      .seatDefinitions()
      .where((d) => !d.isDriver)
      .toList();
  return [
    for (var i = 0; i < definitions.length; i++)
      TripSeat(
        label: definitions[i].label,
        number: i + 1,
        row: definitions[i].row,
        column: definitions[i].column,
        state: mine == i + 1
            ? TripSeatState.mine
            : occupied.contains(i + 1)
            ? TripSeatState.occupied
            : TripSeatState.available,
      ),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  List<TripSeat> seats,
  String vehicleType,
) async {
  await tester.binding.setSurfaceSize(const Size(500, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: SingleChildScrollView(
          child: TripSeatMap(seats: seats, vehicleType: vehicleType),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a Hiace trip renders the 14-seat Hiace cabin', (tester) async {
    await _pump(tester, _seatsFor(VehicleSeatLayouts.hiace), 'Hiace');

    expect(find.byType(VehicleSeat), findsNWidgets(14));
    for (var seat = 1; seat <= 14; seat++) {
      expect(find.text('$seat'), findsOneWidget);
    }
  });

  testWidgets('a Coaster trip renders the 30-seat Coaster cabin', (
    tester,
  ) async {
    await _pump(tester, _seatsFor(VehicleSeatLayouts.coaster), 'Coaster');

    expect(find.byType(VehicleSeat), findsNWidgets(30));
    expect(find.text('30'), findsOneWidget);
    // The door only exists on the Coaster cabin.
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
  });

  testWidgets('the Hiace cabin has no door and the Coaster one has', (
    tester,
  ) async {
    await _pump(tester, _seatsFor(VehicleSeatLayouts.hiace), 'Hiace');
    expect(find.byIcon(Icons.sensor_door_outlined), findsNothing);
  });

  testWidgets('a Coaster is not drawn with the Hiace seat count', (
    tester,
  ) async {
    await _pump(tester, _seatsFor(VehicleSeatLayouts.coaster), 'Coaster');
    expect(find.byType(VehicleSeat), isNot(findsNWidgets(14)));
  });

  testWidgets('seat availability comes from the data, not the layout', (
    tester,
  ) async {
    final seats = _seatsFor(
      VehicleSeatLayouts.coaster,
      occupied: {2, 3, 4},
      mine: 7,
    );
    await _pump(tester, seats, 'Coaster');

    expect(seats.where((s) => s.isOccupied), hasLength(3));
    expect(seats.where((s) => s.isMine), hasLength(1));
    expect(seats.where((s) => s.isAvailable), hasLength(26));
    expect(find.byType(VehicleSeat), findsNWidgets(30));
  });

  testWidgets('a Coaster still carrying Hiace seats renders every seat', (
    tester,
  ) async {
    // The placeholder row in production: typed Coaster, 14 seats stored. Every
    // stored seat is drawn, and the vehicle keeps its own cabin — a stale seat
    // configuration is a data problem, not grounds for drawing a different
    // vehicle.
    await _pump(tester, _seatsFor(VehicleSeatLayouts.hiace), 'Coaster');

    expect(find.byType(VehicleSeat), findsNWidgets(14));
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
  });

  testWidgets('an unknown vehicle type still renders every real seat', (
    tester,
  ) async {
    await _pump(tester, _seatsFor(VehicleSeatLayouts.hiace), 'Karsan e-ATA');

    expect(find.byType(VehicleSeat), findsNWidgets(14));
  });

  testWidgets('an empty seat map renders nothing rather than throwing', (
    tester,
  ) async {
    await _pump(tester, const [], 'Coaster');

    expect(find.byType(VehicleSeat), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
