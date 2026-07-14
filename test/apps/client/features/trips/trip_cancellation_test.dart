import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/cancel_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_details_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trips_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/watch_trips_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';

// Regression coverage for "Cancel Trip is offered on every enrolled trip, and
// cancelling does nothing": the button showed for any upcoming trip regardless
// of payment state, and the flow never reached Supabase — the seat stayed taken
// and the payment stayed in the dashboard's review queue.

TripData _trip({
  TripStatus status = TripStatus.upcoming,
  PaymentStatus paymentStatus = PaymentStatus.pending,
}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-TEST',
    status: status,
    pickup: 'A',
    destination: 'B',
    dateLabel: 'Today',
    timeLabel: '08:00',
    driverName: 'Sam',
    driverPhone: '',
    driverInitials: 'SA',
    driverRating: 4.8,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: const ['1'],
    paymentStatus: paymentStatus,
    fare: 'EGP 50',
  );
}

class _FakeRepo implements TripsRepository {
  _FakeRepo(this.trips);

  List<TripData> trips;
  final List<String> cancelled = [];

  @override
  Future<List<TripData>> getTrips() async => trips;

  @override
  Future<TripData?> getTripById(String id) async =>
      trips.where((trip) => trip.id == id).firstOrNull;

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    cancelled.add(bookingId);
    // What the RPC does: the booking lands in Cancelled and the seat is freed.
    trips = trips
        .map(
          (trip) => trip.id == bookingId
              ? _trip(
                  status: TripStatus.cancelled,
                  paymentStatus: PaymentStatus.cancelled,
                )
              : trip,
        )
        .toList();
  }

  @override
  Stream<void> watchTripChanges() => const Stream.empty();
}

TripsCubit _cubit(_FakeRepo repo) {
  return TripsCubit(
    getTrips: GetTripsUseCase(repo),
    getTripDetails: GetTripDetailsUseCase(repo),
    watchTrips: WatchTripsUseCase(repo),
    cancelBooking: CancelBookingUseCase(repo),
  );
}

void main() {
  group('canBeCancelled', () {
    test('allows cancelling while the dashboard has not approved payment', () {
      expect(_trip(paymentStatus: PaymentStatus.pending).canBeCancelled, isTrue);
      expect(
        _trip(paymentStatus: PaymentStatus.underReview).canBeCancelled,
        isTrue,
      );
    });

    test('refuses once the payment is approved and the seat is paid for', () {
      expect(_trip(paymentStatus: PaymentStatus.paid).canBeCancelled, isFalse);
    });

    test('refuses on trips that already started, finished, or were cancelled', () {
      for (final status in [
        TripStatus.inProgress,
        TripStatus.completed,
        TripStatus.cancelled,
      ]) {
        expect(_trip(status: status).canBeCancelled, isFalse, reason: '$status');
      }
    });
  });

  group('TripsCubit.cancelTrip', () {
    test('cancels an unapproved booking and reloads it as cancelled', () async {
      final repo = _FakeRepo([_trip()]);
      final cubit = _cubit(repo);
      await cubit.loadTripDetails('b1');

      await cubit.cancelTrip(_trip(), 'Personal plans');

      expect(repo.cancelled, ['b1']);
      final state = cubit.state as TripsLoaded;
      expect(state.selectedTrip?.status, TripStatus.cancelled);
      expect(state.cancelledReference, 'BMT-TEST');
      expect(state.cancelInFlight, isFalse);
      await cubit.close();
    });

    test('never reaches Supabase for an approved booking', () async {
      final repo = _FakeRepo([_trip(paymentStatus: PaymentStatus.paid)]);
      final cubit = _cubit(repo);
      await cubit.loadTripDetails('b1');

      await cubit.cancelTrip(
        _trip(paymentStatus: PaymentStatus.paid),
        'Personal plans',
      );

      expect(repo.cancelled, isEmpty);
      final state = cubit.state as TripsLoaded;
      expect(state.cancelFailure, isNotNull);
      expect(state.selectedTrip?.status, TripStatus.upcoming);
      await cubit.close();
    });
  });
}
