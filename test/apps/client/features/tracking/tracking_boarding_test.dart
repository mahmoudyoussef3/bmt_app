import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/confirm_boarding_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

/// §14 is the rule these tests exist for: tracking visibility is per booking,
/// never per trip. A rider who boards stops seeing the vehicle; every rider still
/// waiting on the same trip keeps seeing it; the captain never stops publishing.
void main() {
  group('rider eligibility', () {
    test('a paid, waiting rider may track and may confirm boarding', () {
      const rider = TrackingRider(bookingStatus: 'confirmed');

      expect(rider.canTrackVehicle, isTrue);
      expect(rider.canConfirmBoarding, isTrue);
      expect(rider.hasBoarded, isFalse);
    });

    test('a boarded rider loses tracking and has nothing left to confirm', () {
      const rider = TrackingRider(bookingStatus: 'boarded');

      expect(rider.hasBoarded, isTrue);
      expect(rider.canTrackVehicle, isFalse);
      expect(rider.canConfirmBoarding, isFalse);
    });

    test('a captain-checked-in rider counts as aboard from the manifest side',
        () {
      const rider = TrackingRider(status: 'confirmed', bookingStatus: 'confirmed');

      expect(rider.hasBoarded, isTrue);
      expect(rider.canTrackVehicle, isFalse);
    });

    test('an unknown booking status fails open on tracking — the database is '
        'the boundary, and a missing field must not take a waiting rider\'s '
        'map away', () {
      const rider = TrackingRider();

      expect(rider.canTrackVehicle, isTrue);
      expect(
        rider.canConfirmBoarding,
        isFalse,
        reason: 'but it does not offer an action that would be refused',
      );
    });
  });

  group('the rider\'s station on the board', () {
    test('is matched by route point id, so two stops sharing a name are not '
        'confused', () {
      final trip = _trip(
        rider: const TrackingRider(
          bookingStatus: 'confirmed',
          boardingPointId: 'rp-2',
          boardingName: 'محطة بنها',
        ),
        stations: StationBoard([
          _station(1, 'محطة بنها', routePointId: 'rp-1'),
          _station(2, 'محطة بنها', routePointId: 'rp-2', arrived: DateTime(2026, 8, 11, 8, 40)),
        ]),
      );

      expect(trip.riderStation?.sequence, 2);
      expect(trip.isVehicleAtRiderStation, isTrue);
    });

    test('the vehicle standing somewhere else is not at the rider\'s stop', () {
      final trip = _trip(
        rider: const TrackingRider(
          bookingStatus: 'confirmed',
          boardingPointId: 'rp-2',
        ),
        stations: StationBoard([
          _station(1, 'A', routePointId: 'rp-1', arrived: DateTime(2026, 8, 11, 8, 40)),
          _station(2, 'B', routePointId: 'rp-2'),
        ]),
      );

      expect(trip.isVehicleAtRiderStation, isFalse);
    });

    test('no board yet means no station and no boarding step', () {
      final trip = _trip(rider: const TrackingRider(bookingStatus: 'confirmed'));

      expect(trip.riderStation, isNull);
      expect(trip.isVehicleAtRiderStation, isFalse);
    });
  });

  group('confirming boarding', () {
    test('calls the server with this rider\'s own booking id', () async {
      final datasource = _FakeDatasource(
        trip: _trip(rider: const TrackingRider(bookingStatus: 'confirmed')),
      );
      final cubit = _cubit(datasource);
      await cubit.load();

      await cubit.confirmBoarding();

      expect(datasource.confirmedBookingId, 'booking-1');
      await cubit.close();
    });

    test('a successful confirmation drops this rider\'s position feed while '
        'the captain keeps publishing', () async {
      final positions = StreamController<TrackingPoint>.broadcast();
      final datasource = _FakeDatasource(
        trip: _trip(rider: const TrackingRider(bookingStatus: 'confirmed')),
        positions: positions.stream,
      );
      final cubit = _cubit(datasource);

      await cubit.load();
      expect(datasource.positionSubscriptions, 1);

      // The server flips the booking; the refetch picks it up.
      datasource.trip = _trip(
        rider: const TrackingRider(bookingStatus: 'boarded'),
      );
      await cubit.confirmBoarding();

      final loaded = cubit.state as TrackingLoaded;
      expect(loaded.data.rider.hasBoarded, isTrue);
      expect(loaded.data.rider.canTrackVehicle, isFalse);
      expect(
        positions.hasListener,
        isFalse,
        reason: 'this rider stops consuming; nothing stopped the captain',
      );

      await positions.close();
      await cubit.close();
    });

    test('a refused confirmation keeps the trip on screen and says why',
        () async {
      final datasource = _FakeDatasource(
        trip: _trip(rider: const TrackingRider(bookingStatus: 'confirmed')),
      )..boardingFailure = Exception('لم تصل السيارة إلى محطتك بعد');
      final cubit = _cubit(datasource);
      await cubit.load();

      await cubit.confirmBoarding();

      final loaded = cubit.state as TrackingLoaded;
      expect(loaded.boardingError, 'لم تصل السيارة إلى محطتك بعد');
      expect(loaded.isBoarding, isFalse);
      expect(loaded.data.rider.hasBoarded, isFalse);
      await cubit.close();
    });

    test('the refusal can be dismissed', () async {
      final datasource = _FakeDatasource(
        trip: _trip(rider: const TrackingRider(bookingStatus: 'confirmed')),
      )..boardingFailure = Exception('boom');
      final cubit = _cubit(datasource);
      await cubit.load();
      await cubit.confirmBoarding();

      cubit.dismissBoardingError();

      expect((cubit.state as TrackingLoaded).boardingError, isNull);
      await cubit.close();
    });

    test('a second tap while the first is in flight is dropped', () async {
      final gate = Completer<void>();
      final datasource = _FakeDatasource(
        trip: _trip(rider: const TrackingRider(bookingStatus: 'confirmed')),
      )..hold = gate.future;
      final cubit = _cubit(datasource);
      await cubit.load();

      final first = cubit.confirmBoarding();
      await Future<void>.delayed(Duration.zero);
      final second = cubit.confirmBoarding();
      gate.complete();
      await Future.wait([first, second]);

      expect(datasource.confirmCalls, 1);
      await cubit.close();
    });

    test('a rider with no booking has nothing to confirm', () async {
      final datasource = _FakeDatasource(trip: const TrackingTripData.none());
      final cubit = _cubit(datasource);
      await cubit.load();

      await cubit.confirmBoarding();

      expect(datasource.confirmCalls, 0);
      await cubit.close();
    });
  });
}

TrackingCubit _cubit(TrackingDatasource datasource) {
  final repository = TrackingRepositoryImpl(datasource);
  return TrackingCubit(
    getTrackingTrip: GetTrackingTripUseCase(repository),
    watchVehiclePosition: WatchVehiclePositionUseCase(repository),
    watchTrackingTrip: WatchTrackingTripUseCase(repository),
    confirmBoarding: ConfirmBoardingUseCase(repository),
  );
}

TrackingTripData _trip({
  required TrackingRider rider,
  StationBoard stations = const StationBoard.empty(),
}) {
  return TrackingTripData(
    tripId: 'trip-1',
    bookingId: 'booking-1',
    tripState: TrackingTripState.boarding,
    stations: stations,
    rider: rider,
    stops: const [
      RouteStop(name: 'محطة بنها', latitude: 30.46, longitude: 31.18, order: 0),
      RouteStop(name: 'كفر شكر', latitude: 30.30, longitude: 31.25, order: 1),
    ],
  );
}

TripStation _station(
  int sequence,
  String name, {
  String? routePointId,
  DateTime? arrived,
}) {
  return TripStation(
    id: 'st-$sequence',
    name: name,
    sequence: sequence,
    status: arrived != null
        ? TripStationStatus.waitingForPassengers
        : TripStationStatus.upcoming,
    routePointId: routePointId,
    actualArrivalAt: arrived,
  );
}

class _FakeDatasource implements TrackingDatasource {
  _FakeDatasource({required this.trip, Stream<TrackingPoint>? positions})
    : positions = positions ?? const Stream.empty();

  TrackingTripData trip;
  final Stream<TrackingPoint> positions;

  String? confirmedBookingId;
  int confirmCalls = 0;
  int positionSubscriptions = 0;
  Object? boardingFailure;
  Future<void>? hold;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async => trip;

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) {
    positionSubscriptions++;
    return positions;
  }

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<void> confirmBoarding(String bookingId) async {
    confirmCalls++;
    confirmedBookingId = bookingId;
    if (hold != null) await hold;
    if (boardingFailure case final error?) throw error;
  }
}
