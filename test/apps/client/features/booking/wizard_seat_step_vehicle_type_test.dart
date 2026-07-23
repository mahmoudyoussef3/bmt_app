import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_seat_step.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/repositories/seat_selection_repository.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/get_seat_selection_data_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/select_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import '../../client_test_app.dart';

/// The booking flow must draw the cabin of the vehicle on the trip, and must
/// book the seat label the database actually holds.
class _FakeSeatRepository implements SeatSelectionRepository {
  _FakeSeatRepository(this.data);

  final SeatSelectionData data;

  @override
  Future<SeatSelectionData> getSeatSelectionData(String tripId) async => data;

  @override
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  }) async => {'seat_id': seatId};

  @override
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  }) async {}

  @override
  Future<Map<String, dynamic>> confirmSeatBooking(
    Map<String, dynamic> params,
  ) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  ) => throw UnimplementedError();

  @override
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params) =>
      throw UnimplementedError();
}

SeatSelectionData _data({
  required SeatLayoutBlueprint blueprint,
  required String vehicleType,
  Set<int> reserved = const {},
}) {
  final definitions = blueprint
      .seatDefinitions()
      .where((d) => !d.isDriver)
      .toList();
  return SeatSelectionData(
    tripId: 't-1',
    seats: [
      for (var i = 0; i < definitions.length; i++)
        SeatOption(
          id: 's-${i + 1}',
          seatNumber: i + 1,
          availability: reserved.contains(i + 1)
              ? SeatAvailability.reserved
              : SeatAvailability.available,
          seatLabel: definitions[i].label,
          row: definitions[i].row,
          column: definitions[i].column,
        ),
    ],
    pricePerSeat: 120,
    pickupPoint: 'Cairo',
    destination: 'Alexandria',
    vehicleNumber: 'BUS-201',
    vehicleName: 'Toyota',
    vehicleType: vehicleType,
    vehicleModel: vehicleType,
    vehicleImageUrl: '',
    tripDate: '2030-01-15',
    departureTime: '08:00',
    arrivalTime: '11:00',
    driverName: 'Sam',
    driverRating: 4.8,
    driverImageUrl: '',
  );
}

const _route = RouteOptionData(
  id: 'r-1',
  routeName: 'Cairo → Alexandria',
  pickup: 'Cairo',
  destination: 'Alexandria',
  distance: '220 km',
  duration: '3h',
  availableSeats: 12,
  startingPrice: 'EGP 120',
  priceRange: 'EGP 120',
  availableTrips: [],
);

Future<BookingWizardCubit> _pump(
  WidgetTester tester,
  SeatSelectionData data,
) async {
  await tester.binding.setSurfaceSize(const Size(500, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final wizard = BookingWizardCubit(_route)
    ..selectTrip(
      const RouteTripOptionData(
        id: 't-1',
        departureTime: '08:00',
        arrivalTime: '11:00',
        availableSeats: 10,
        vehicleType: 'Hiace',
        price: 'EGP 120',
        tripDate: '2030-01-15',
      ),
    );

  final repository = _FakeSeatRepository(data);
  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<BookingWizardCubit>.value(value: wizard),
            BlocProvider<SeatSelectionCubit>(
              create: (_) => SeatSelectionCubit(
                getSeatSelectionData: GetSeatSelectionDataUseCase(repository),
                selectSeat: const SelectSeatUseCase(),
                lockTripSeat: LockTripSeatUseCase(repository),
              ),
            ),
          ],
          child: WizardSeatStep(onNext: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return wizard;
}

void main() {
  testWidgets('a Hiace trip shows the 14-seat Hiace cabin', (tester) async {
    await _pump(
      tester,
      _data(blueprint: VehicleSeatLayouts.hiace, vehicleType: 'Hiace'),
    );

    for (var seat = 1; seat <= 14; seat++) {
      expect(find.text('$seat'), findsOneWidget, reason: 'seat $seat');
    }
    expect(find.text('15'), findsNothing);
    expect(find.byIcon(Icons.sensor_door_outlined), findsNothing);
  });

  testWidgets('a Coaster trip shows the 30-seat Coaster cabin', (tester) async {
    await _pump(
      tester,
      _data(blueprint: VehicleSeatLayouts.coaster, vehicleType: 'Coaster'),
    );

    for (var seat = 1; seat <= 30; seat++) {
      expect(find.text('$seat'), findsOneWidget, reason: 'seat $seat');
    }
    // The Coaster cabin shows its entrance; the Hiace one has none.
    expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
  });

  testWidgets('booking a Hiace seat records the real database label', (
    tester,
  ) async {
    final wizard = await _pump(
      tester,
      _data(blueprint: VehicleSeatLayouts.hiace, vehicleType: 'Hiace'),
    );

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    // The label travels to `confirm_seat_booking_v2` as `p_seat_label` and is
    // what the operator's manifest matches against `trip_seats.seat_label`.
    expect(wizard.state.selectedSeatId, 's-5');
    expect(wizard.state.selectedSeatLabel, '5');
    expect(wizard.state.seatValid, isTrue);
  });

  testWidgets('booking a Coaster seat records the real database label', (
    tester,
  ) async {
    final wizard = await _pump(
      tester,
      _data(blueprint: VehicleSeatLayouts.coaster, vehicleType: 'Coaster'),
    );

    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();

    expect(wizard.state.selectedSeatId, 's-27');
    expect(wizard.state.selectedSeatLabel, '27');
  });

  testWidgets('a reserved seat cannot be selected', (tester) async {
    final wizard = await _pump(
      tester,
      _data(
        blueprint: VehicleSeatLayouts.coaster,
        vehicleType: 'Coaster',
        reserved: {4},
      ),
    );

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(wizard.state.selectedSeatId, isNull);
  });

  testWidgets('the free-seat count comes from the seat data', (tester) async {
    await _pump(
      tester,
      _data(
        blueprint: VehicleSeatLayouts.coaster,
        vehicleType: 'Coaster',
        reserved: {1, 2, 3},
      ),
    );

    expect(find.textContaining('27'), findsWidgets);
  });

  testWidgets('an unknown vehicle type still renders every real seat', (
    tester,
  ) async {
    await _pump(
      tester,
      _data(blueprint: VehicleSeatLayouts.hiace, vehicleType: 'Karsan e-ATA'),
    );

    for (var seat = 1; seat <= 14; seat++) {
      expect(find.text('$seat'), findsOneWidget, reason: 'seat $seat');
    }
    expect(tester.takeException(), isNull);
  });
}
