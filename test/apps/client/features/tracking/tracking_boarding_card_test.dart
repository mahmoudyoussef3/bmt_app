import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/confirm_boarding_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/formatters/tracking_labels.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/sheet/tracking_boarding_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/sheet/tracking_stops_list.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../../client_test_app.dart';

/// §21: the rider must never be left wondering why the map went away. These
/// tests pin the three states of the boarding step and the explanation that
/// replaces tracking once they are aboard.
void main() {
  final now = DateTime(2026, 8, 11, 8, 40);

  group('boarding card', () {
    testWidgets('waiting for the vehicle: no action, and it says what it is '
        'waiting for', (tester) async {
      await _pumpCard(
        tester,
        trip: _trip(
          rider: const TrackingRider(
            bookingStatus: 'confirmed',
            boardingPointId: 'rp-1',
            boardingName: 'Banha',
          ),
          stations: StationBoard([_station(1, 'Banha', routePointId: 'rp-1')]),
        ),
      );

      expect(find.text('Waiting for the vehicle'), findsOneWidget);
      expect(find.textContaining('Banha'), findsOneWidget);
      expect(find.text("Yes, I'm on board"), findsNothing);
    });

    testWidgets('vehicle at the stop: the confirm action appears and reports '
        'who else is still boarding', (tester) async {
      await _pumpCard(
        tester,
        trip: _trip(
          rider: const TrackingRider(
            bookingStatus: 'confirmed',
            boardingPointId: 'rp-1',
            boardingName: 'Banha',
          ),
          stations: StationBoard([
            _station(
              1,
              'Banha',
              routePointId: 'rp-1',
              arrived: now,
              expected: 3,
              boarded: 1,
              pending: 2,
            ),
          ]),
        ),
      );

      expect(find.text('Have you boarded?'), findsOneWidget);
      expect(find.text("Yes, I'm on board"), findsOneWidget);
      expect(find.text('Waiting for 2 passengers'), findsOneWidget);
    });

    testWidgets('tapping confirm asks the server', (tester) async {
      final datasource = _StubDatasource();
      final cubit = await _pumpCard(
        tester,
        datasource: datasource,
        load: true,
        trip: _trip(
          rider: const TrackingRider(
            bookingStatus: 'confirmed',
            boardingPointId: 'rp-1',
          ),
          stations: StationBoard([
            _station(1, 'Banha', routePointId: 'rp-1', arrived: now),
          ]),
        ),
      );

      await tester.tap(find.text("Yes, I'm on board"));
      await tester.pump();

      expect(datasource.confirmedBookingId, 'booking-1');

      // Closed through `runAsync`: `close()` completes on a real event-loop
      // turn, which the fake async inside `testWidgets` never advances, and the
      // ETA ticker it cancels is a pending timer the test would otherwise fail on.
      await tester.runAsync(cubit.close);
    });

    testWidgets('boarded: the confirmation explains why tracking stopped, '
        'rather than leaving a rider to wonder', (tester) async {
      await _pumpCard(
        tester,
        trip: _trip(rider: const TrackingRider(bookingStatus: 'boarded')),
      );

      expect(find.text('Boarding confirmed'), findsOneWidget);
      expect(
        find.textContaining("no longer need to follow the vehicle's location"),
        findsOneWidget,
      );
      expect(find.text("Yes, I'm on board"), findsNothing);
    });

    testWidgets('a server refusal is shown on the card', (tester) async {
      await _pumpCard(
        tester,
        boardingError: 'The vehicle has not reached your stop yet',
        trip: _trip(
          rider: const TrackingRider(
            bookingStatus: 'confirmed',
            boardingPointId: 'rp-1',
          ),
          stations: StationBoard([
            _station(1, 'Banha', routePointId: 'rp-1', arrived: now),
          ]),
        ),
      );

      expect(
        find.text('The vehicle has not reached your stop yet'),
        findsOneWidget,
      );
    });

    test('a rider with no booking of their own gets no boarding step', () {
      expect(
        TrackingBoardingCard.isRelevantFor(
          _trip(rider: const TrackingRider()),
        ),
        isFalse,
      );
    });

    test('a finished trip has no boarding step', () {
      final trip = TrackingTripData(
        tripId: 'trip-1',
        bookingId: 'booking-1',
        tripState: TrackingTripState.completed,
        rider: const TrackingRider(bookingStatus: 'confirmed'),
        stops: const [],
      );

      expect(TrackingBoardingCard.isRelevantFor(trip), isFalse);
    });
  });

  group('stops list', () {
    testWidgets('a station the captain has left reads as passed, and the list '
        'says its times are estimates', (tester) async {
      await _pumpStops(
        tester,
        rider: const TrackingRider(bookingStatus: 'confirmed'),
        stations: StationBoard([
          _station(
            1,
            'Banha',
            routePointId: 'rp-1',
            arrived: now.subtract(const Duration(minutes: 20)),
            departed: now.subtract(const Duration(minutes: 15)),
          ),
          _station(2, 'Kafr Shukr', routePointId: 'rp-2'),
        ]),
        now: now,
      );

      expect(find.text('Passed'), findsOneWidget);
      expect(find.text('Times may change with traffic'), findsOneWidget);
    });

    testWidgets('a boarded rider still gets the stops and their ETAs',
        (tester) async {
      await _pumpStops(
        tester,
        rider: const TrackingRider(bookingStatus: 'boarded'),
        stations: StationBoard([
          _station(1, 'Banha', routePointId: 'rp-1'),
          _station(2, 'Kafr Shukr', routePointId: 'rp-2'),
        ]),
        now: now,
      );

      expect(find.text('Banha'), findsOneWidget);
      expect(find.text('Kafr Shukr'), findsOneWidget);
    });
  });
}

/// Returns the cubit so a test that actually drives an action can close it
/// before the widget tree is torn down — the ETA ticker is a periodic timer, and
/// `testWidgets` fails a test that leaves one pending.
Future<TrackingCubit> _pumpCard(
  WidgetTester tester, {
  required TrackingTripData trip,
  _StubDatasource? datasource,
  String? boardingError,
  bool load = false,
}) async {
  final source = datasource ?? _StubDatasource();
  source.trip = trip;
  final repository = TrackingRepositoryImpl(source);
  final cubit = TrackingCubit(
    getTrackingTrip: GetTrackingTripUseCase(repository),
    watchVehiclePosition: WatchVehiclePositionUseCase(repository),
    watchTrackingTrip: WatchTrackingTripUseCase(repository),
    confirmBoarding: ConfirmBoardingUseCase(repository),
  );
  addTearDown(cubit.close);
  if (load) await cubit.load();

  await tester.pumpWidget(
    clientTestApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: TrackingBoardingCard(
                trip: trip,
                labels: TrackingLabels(AppLocalizations.of(context)!, 'en'),
                isBoarding: false,
                boardingError: boardingError,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

Future<void> _pumpStops(
  WidgetTester tester, {
  required TrackingRider rider,
  required StationBoard stations,
  required DateTime now,
}) async {
  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => SingleChildScrollView(
            child: TrackingStopsList(
              progress: _snapshot(),
              rider: rider,
              labels: TrackingLabels(AppLocalizations.of(context)!, 'en'),
              stations: stations,
              now: now,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

RouteProgressSnapshot _snapshot() {
  return RouteProgressSnapshot(
    phase: TripProgressPhase.headingToPickup,
    hasVehicleFix: false,
    isStale: false,
    isOffRoute: false,
    routeFraction: 0,
    traveledMeters: 0,
    totalRouteMeters: 0,
    nextStopIndex: 0,
    stops: [
      StopProgress(
        stop: const RouteStop(
          name: 'Banha',
          latitude: 30.46,
          longitude: 31.18,
          order: 0,
          id: 'rp-1',
        ),
        status: StopVisitStatus.next,
      ),
      StopProgress(
        stop: const RouteStop(
          name: 'Kafr Shukr',
          latitude: 30.30,
          longitude: 31.25,
          order: 1,
          id: 'rp-2',
        ),
        status: StopVisitStatus.upcoming,
      ),
    ],
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
      RouteStop(name: 'Banha', latitude: 30.46, longitude: 31.18, order: 0),
    ],
  );
}

TripStation _station(
  int sequence,
  String name, {
  String? routePointId,
  DateTime? arrived,
  DateTime? departed,
  int expected = 0,
  int boarded = 0,
  int pending = 0,
}) {
  return TripStation(
    id: 'st-$sequence',
    name: name,
    sequence: sequence,
    status: departed != null
        ? TripStationStatus.departed
        : arrived != null
        ? TripStationStatus.waitingForPassengers
        : TripStationStatus.upcoming,
    routePointId: routePointId,
    actualArrivalAt: arrived,
    actualDepartureAt: departed,
    expectedBoardings: expected,
    boardedCount: boarded,
    pendingCount: pending,
  );
}

class _StubDatasource implements TrackingDatasource {
  String? confirmedBookingId;
  TrackingTripData trip = const TrackingTripData.none();

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async => trip;

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) =>
      const Stream.empty();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<void> confirmBoarding(String bookingId) async =>
      confirmedBookingId = bookingId;
}
