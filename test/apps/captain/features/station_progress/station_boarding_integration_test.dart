import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action_failure.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/repositories/station_progress_repository.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/arrive_at_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/depart_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/get_station_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/resolve_no_show_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/watch_station_board_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/confirm_boarding_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/station_board_mapper.dart';

/// The whole scenario, end to end, with one server standing behind both apps.
///
/// The server here is a Dart re-implementation of the two rules the database
/// enforces — the departure gate and the per-booking tracking boundary — so the
/// test proves the *apps* behave correctly against them and, crucially, that the
/// captain and the rider are looking at the same numbers. That the database
/// really enforces them is proved separately and against the real database, by
/// `supabase/tests/station_boarding_regression.sql`; this suite would pass
/// against a server that had forgotten the rules, which is exactly why both
/// exist.
void main() {
  test('a trip from first station to second, with one rider boarding, one '
      'no-showing, and a third still waiting down the route', () async {
    final server = _FakeServer(
      stations: [
        _ServerStation(
          sequence: 1,
          name: 'محطة بنها',
          routePointId: 'rp-1',
          expectedArrival: DateTime(2026, 8, 11, 8, 40),
          expectedDeparture: DateTime(2026, 8, 11, 8, 45),
          minDwell: const Duration(minutes: 5),
        ),
        _ServerStation(
          sequence: 2,
          name: 'محطة كفر شكر',
          routePointId: 'rp-2',
          expectedArrival: DateTime(2026, 8, 11, 8, 58),
          expectedDeparture: DateTime(2026, 8, 11, 9, 1),
          minDwell: const Duration(minutes: 3),
        ),
      ],
      passengers: [
        // Two riders at station 1: one will board, one will not turn up.
        _ServerPassenger(id: 'pax-a', bookingId: 'bk-a', routePointId: 'rp-1'),
        _ServerPassenger(id: 'pax-c', bookingId: 'bk-c', routePointId: 'rp-1'),
        // And one waiting further down the route.
        _ServerPassenger(id: 'pax-b', bookingId: 'bk-b', routePointId: 'rp-2'),
      ],
    );

    final captain = _captainCubit(server);
    final riderA = _riderCubit(server, 'bk-a');
    final riderB = _riderCubit(server, 'bk-b');

    // ── 1-2. The trip starts and the captain reaches the first station ────────
    captain.watch('trip-1');
    await _settle();
    expect(captain.state.board.stations, hasLength(2));

    server.now = DateTime(2026, 8, 11, 8, 42);
    await captain.arriveAtCurrentStation();
    await _settle();

    final atStation = captain.state.board.currentStation!;
    expect(atStation.name, 'محطة بنها');
    expect(atStation.expectedBoardings, 2);
    expect(atStation.pendingCount, 2);

    // ── 3-4. Both riders load; both are still waiting, so both see the bus ────
    await riderA.load();
    await riderB.load();
    expect(_data(riderA).rider.canTrackVehicle, isTrue);
    expect(_data(riderB).rider.canTrackVehicle, isTrue);

    // ── 5-6. Rider A confirms boarding; the captain's count moves ─────────────
    await riderA.confirmBoarding();
    await _settle();

    expect(_data(riderA).rider.hasBoarded, isTrue);
    expect(
      captain.state.board.currentStation!.boardedCount,
      1,
      reason: 'the rider and the captain read the same tally',
    );
    expect(captain.state.board.currentStation!.pendingCount, 1);

    // ── 7-8. One rider outstanding: the captain cannot leave ──────────────────
    var gate = captain.state.board.gateAt(server.now);
    expect(gate.state, StationGateState.waitingForPassengers);
    await captain.departCurrentStation();
    expect(
      captain.state.failure!.failure,
      StationActionFailure.passengersNotBoarded,
    );
    expect(server.departures, isEmpty);

    // ── 9. The missing rider is resolved — with a reason, never a skip ────────
    await captain.resolveNoShow(
      passengerId: 'pax-c',
      reason: NoShowReason.didNotArrive,
    );
    await _settle();
    expect(server.noShowReasons['pax-c'], 'did_not_arrive');
    expect(captain.state.board.currentStation!.pendingCount, 0);

    // ── 10. Boarding is resolved, but the vehicle is not due out yet ──────────
    gate = captain.state.board.gateAt(server.now);
    expect(gate.state, StationGateState.waitingForDepartureTime);
    expect(gate.earliestDeparture, DateTime(2026, 8, 11, 8, 47));
    await captain.departCurrentStation();
    expect(
      captain.state.failure!.failure,
      StationActionFailure.departureTimeNotReached,
    );
    expect(server.departures, isEmpty);

    // ── 11-12. The dwell elapses and the captain may go ───────────────────────
    server.now = DateTime(2026, 8, 11, 8, 48);
    expect(
      captain.state.board.gateAt(server.now).state,
      StationGateState.ready,
    );

    await captain.departCurrentStation();
    await _settle();
    expect(server.departures, ['محطة بنها']);
    expect(captain.state.board.currentStation, isNull);
    expect(captain.state.board.nextStation?.name, 'محطة كفر شكر');

    // A retry must refuse rather than advance the second station too.
    await captain.departCurrentStation();
    expect(
      captain.state.failure!.failure,
      StationActionFailure.noCurrentStation,
    );
    expect(server.departures, hasLength(1));

    // ── 13-14. Tracking visibility is per booking, not per trip ───────────────
    await riderA.refresh();
    await riderB.refresh();

    expect(
      _data(riderA).rider.canTrackVehicle,
      isFalse,
      reason: 'rider A is aboard and no longer tracks the vehicle',
    );
    expect(
      server.fixReadsAllowedFor('bk-a'),
      isFalse,
      reason: 'and the server refuses them the positions, not just the app',
    );
    expect(
      _data(riderB).rider.canTrackVehicle,
      isTrue,
      reason: 'rider B is still waiting at station 2 and must keep the map',
    );
    expect(server.fixReadsAllowedFor('bk-b'), isTrue);
    expect(
      server.publishing,
      isTrue,
      reason: 'the captain never stopped publishing — §15',
    );

    // ── The boarded rider keeps their journey, minus the vehicle ──────────────
    final aData = _data(riderA);
    expect(aData.stations.stations, hasLength(2));
    expect(aData.stations.stations.first.hasDeparted, isTrue);
    expect(
      aData.stations.etas(server.now).last.at,
      isNotNull,
      reason: 'ETAs survive losing GPS — they come off the board',
    );

    await captain.close();
    await riderA.close();
    await riderB.close();
  });

  test('a rider cannot confirm boarding before the vehicle reaches their stop',
      () async {
    final server = _FakeServer(
      stations: [
        _ServerStation(sequence: 1, name: 'A', routePointId: 'rp-1'),
        _ServerStation(sequence: 2, name: 'B', routePointId: 'rp-2'),
      ],
      passengers: [
        _ServerPassenger(id: 'pax-b', bookingId: 'bk-b', routePointId: 'rp-2'),
      ],
    );

    final captain = _captainCubit(server);
    captain.watch('trip-1');
    await _settle();
    await captain.arriveAtCurrentStation();
    await _settle();

    final rider = _riderCubit(server, 'bk-b');
    await rider.load();
    expect(_data(rider).isVehicleAtRiderStation, isFalse);

    await rider.confirmBoarding();

    expect((rider.state as TrackingLoaded).boardingError, isNotNull);
    expect(_data(rider).rider.hasBoarded, isFalse);
    expect(
      captain.state.board.currentStation!.boardedCount,
      0,
      reason: 'a rider at the next stop cannot clear this stop\'s requirement',
    );

    await captain.close();
    await rider.close();
  });

  test('a rider whose booking is not theirs is refused', () async {
    final server = _FakeServer(
      stations: [_ServerStation(sequence: 1, name: 'A', routePointId: 'rp-1')],
      passengers: [
        _ServerPassenger(id: 'pax-a', bookingId: 'bk-a', routePointId: 'rp-1'),
      ],
    );

    // The client cubit only ever names the booking it loaded, so this is the
    // server refusing a forged id — the check that has to live server-side.
    expect(
      () => server.confirmBoarding('bk-someone-else'),
      throwsA(isA<Exception>()),
    );
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

TrackingTripData _data(TrackingCubit cubit) =>
    (cubit.state as TrackingLoaded).data;

StationProgressCubit _captainCubit(_FakeServer server) {
  final repository = _CaptainRepository(server);
  return StationProgressCubit(
    watchBoard: WatchStationBoardUseCase(repository),
    arriveAtStation: ArriveAtStationUseCase(repository),
    departStation: DepartStationUseCase(repository),
    resolveNoShow: ResolveNoShowUseCase(repository),
    getStationPassengers: GetStationPassengersUseCase(repository),
  );
}

TrackingCubit _riderCubit(_FakeServer server, String bookingId) {
  final repository = TrackingRepositoryImpl(_RiderDatasource(server, bookingId));
  return TrackingCubit(
    getTrackingTrip: GetTrackingTripUseCase(repository),
    watchTrackingTrip: WatchTrackingTripUseCase(repository),
    confirmBoarding: ConfirmBoardingUseCase(repository),
  );
}

// ───────────────────────────────────────────────────────────────────────────────
// The server
// ───────────────────────────────────────────────────────────────────────────────

class _ServerStation {
  _ServerStation({
    required this.sequence,
    required this.name,
    required this.routePointId,
    this.expectedArrival,
    this.expectedDeparture,
    this.minDwell = Duration.zero,
  });

  final int sequence;
  final String name;
  final String routePointId;
  final DateTime? expectedArrival;
  final DateTime? expectedDeparture;
  final Duration minDwell;

  DateTime? actualArrival;
  DateTime? actualDeparture;
}

class _ServerPassenger {
  _ServerPassenger({
    required this.id,
    required this.bookingId,
    required this.routePointId,
  });

  final String id;
  final String bookingId;
  final String routePointId;

  /// `trip_passengers.status`
  String status = 'reserved';

  /// `operation_bookings.status`
  String bookingStatus = 'confirmed';
}

/// Re-implements the two server-side rules the apps are not allowed to decide.
class _FakeServer {
  _FakeServer({required this.stations, required this.passengers});

  final List<_ServerStation> stations;
  final List<_ServerPassenger> passengers;

  DateTime now = DateTime(2026, 8, 11, 8, 30);
  final departures = <String>[];
  final noShowReasons = <String, String>{};

  /// The captain publishes for the whole trip, regardless of anyone boarding.
  bool publishing = true;

  final _boards = StreamController<StationBoard>.broadcast();

  Stream<StationBoard> get boards => _boards.stream;

  void _push() => _boards.add(board());

  _ServerStation? get _current => stations
      .cast<_ServerStation?>()
      .firstWhere(
        (s) => s!.actualArrival != null && s.actualDeparture == null,
        orElse: () => null,
      );

  StationBoard board() {
    return StationBoardMapper.fromRows([
      for (final station in stations)
        {
          'id': 'st-${station.sequence}',
          'trip_id': 'trip-1',
          'route_point_id': station.routePointId,
          'point_name': station.name,
          'sequence': station.sequence,
          'expected_arrival_at': station.expectedArrival?.toIso8601String(),
          'expected_departure_at': station.expectedDeparture?.toIso8601String(),
          'min_dwell_seconds': station.minDwell.inSeconds,
          'actual_arrival_at': station.actualArrival?.toIso8601String(),
          'actual_departure_at': station.actualDeparture?.toIso8601String(),
          'status': station.actualDeparture != null
              ? 'departed'
              : station.actualArrival != null
              ? 'waiting_for_passengers'
              : 'upcoming',
          ..._counts(station),
        },
    ]);
  }

  Map<String, int> _counts(_ServerStation station) {
    final here = passengers.where((p) => p.routePointId == station.routePointId);
    return {
      'expected_boardings': here.where((p) => p.status != 'cancelled').length,
      'boarded_count': here.where((p) => p.status == 'confirmed').length,
      'pending_count': here.where((p) => p.status == 'reserved').length,
      'no_show_count': here.where((p) => p.status == 'no_show').length,
    };
  }

  void arrive() {
    if (_current != null) return; // idempotent
    final next = stations.firstWhere(
      (s) => s.actualDeparture == null,
      orElse: () => throw Exception('no_pending_station'),
    );
    next.actualArrival = now;
    _push();
  }

  /// The gate, server-side. Both conditions, in this order, every time.
  void depart() {
    final station = _current;
    if (station == null) throw stationFailureFrom('no_current_station');

    final pending = _counts(station)['pending_count']!;
    if (pending > 0) {
      throw stationFailureFrom('passengers_not_boarded:$pending');
    }

    final earliest = _earliest(station);
    if (earliest != null && now.isBefore(earliest)) {
      throw stationFailureFrom(
        'departure_time_not_reached:'
        '${earliest.hour.toString().padLeft(2, '0')}:'
        '${earliest.minute.toString().padLeft(2, '0')}',
      );
    }

    station.actualDeparture = now;
    departures.add(station.name);
    _push();
  }

  DateTime? _earliest(_ServerStation station) {
    final dwell = station.actualArrival?.add(station.minDwell);
    final planned = station.expectedDeparture;
    if (dwell == null) return planned;
    if (planned == null) return dwell;
    return dwell.isAfter(planned) ? dwell : planned;
  }

  void resolveNoShow(String passengerId, String reason) {
    final passenger = passengers.firstWhere((p) => p.id == passengerId);
    if (passenger.status != 'reserved') {
      throw stationFailureFrom('passenger_not_pending:${passenger.status}');
    }
    passenger.status = 'no_show';
    noShowReasons[passengerId] = reason;
    _push();
  }

  void confirmBoarding(String bookingId) {
    final passenger = passengers.cast<_ServerPassenger?>().firstWhere(
      (p) => p!.bookingId == bookingId,
      orElse: () => null,
    );
    if (passenger == null) throw Exception('not_your_booking');
    if (passenger.bookingStatus == 'boarded') return;

    final station = _current;
    if (station == null) throw Exception('vehicle_not_at_station');
    if (station.routePointId != passenger.routePointId) {
      throw Exception('not_your_station');
    }

    passenger.status = 'confirmed';
    passenger.bookingStatus = 'boarded';
    _push();
  }

  /// The passenger arm of `can_read_trip_fixes`: still waiting, and no longer.
  bool fixReadsAllowedFor(String bookingId) {
    final passenger = passengers.firstWhere((p) => p.bookingId == bookingId);
    return passenger.bookingStatus == 'confirmed';
  }

  _ServerPassenger passengerFor(String bookingId) =>
      passengers.firstWhere((p) => p.bookingId == bookingId);
}

class _CaptainRepository implements StationProgressRepository {
  _CaptainRepository(this.server);

  final _FakeServer server;

  @override
  Stream<StationBoard> watchBoard(String tripId) async* {
    yield server.board();
    yield* server.boards;
  }

  @override
  Future<void> arriveAtStation(String tripId) async => server.arrive();

  @override
  Future<void> departStation(String tripId) async => server.depart();

  @override
  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) async => server.resolveNoShow(passengerId, reason.wireValue);

  @override
  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) async => [
    for (final p in server.passengers)
      if (p.routePointId == routePointId)
        StationPassenger(
          id: p.id,
          name: p.id,
          seatLabel: 'A1',
          phone: '0100',
          status: stationPassengerStatusFrom(p.status),
        ),
  ];
}

class _RiderDatasource implements TrackingDatasource {
  _RiderDatasource(this.server, this.bookingId);

  final _FakeServer server;
  final String bookingId;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    final passenger = server.passengerFor(this.bookingId);
    return TrackingTripData(
      tripId: 'trip-1',
      bookingId: this.bookingId,
      tripState: TrackingTripState.boarding,
      stations: server.board(),
      stops: [
        for (final station in server.stations)
          RouteStop(
            id: station.routePointId,
            name: station.name,
            latitude: 30,
            longitude: 31,
            order: station.sequence - 1,
          ),
      ],
      rider: TrackingRider(
        boardingPointId: passenger.routePointId,
        boardingName: server.stations
            .firstWhere((s) => s.routePointId == passenger.routePointId)
            .name,
        status: passenger.status,
        bookingStatus: passenger.bookingStatus,
      ),
    );
  }

  /// Only ever subscribed to while this rider is eligible — and the server would
  /// refuse the rows regardless.
  @override
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId) =>
      const Stream.empty();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<void> confirmBoarding(String bookingId) async {
    try {
      server.confirmBoarding(bookingId);
    } on Exception {
      throw Exception('لم تصل السيارة إلى محطتك بعد');
    }
  }
}
