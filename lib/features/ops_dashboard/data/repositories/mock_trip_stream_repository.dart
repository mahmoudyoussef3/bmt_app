import 'dart:async';
import 'dart:math';
import '../../domain/models/trip_update.dart';
import '../../domain/models/position.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_event.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/repositories/trip_stream_repository.dart';

class MockTripStreamRepository implements TripStreamRepository {
  final _random = Random();
  final WebSocketService? ws;
  final _controller = StreamController<TripUpdate>.broadcast();

  MockTripStreamRepository({this.ws}) {
    _start();
  }

  void _start() {
    // create a few mock trips and simulate progress
    final trips = List.generate(6, (i) => 'TRIP-${i + 1}');
    final progresses = Map.fromEntries(
      trips.map((t) => MapEntry(t, _random.nextDouble() * 0.6)),
    );

    Timer.periodic(const Duration(seconds: 1), (_) {
      for (var tripId in trips) {
        var p = progresses[tripId]! + 0.02 + _random.nextDouble() * 0.02;
        if (p >= 1.0) p = 1.0;
        progresses[tripId] = p;
        final status = p == 0.0
            ? TripStatus.scheduled
            : (p >= 1.0
                  ? TripStatus.completed
                  : (p > 0.0 && p < 0.5
                        ? TripStatus.active
                        : TripStatus.active));
        final update = TripUpdate(
          tripId: tripId,
          status: status,
          progress: p,
          location: Position(
            lat: 0.1 + p * 0.8,
            lng: 0.1 + _random.nextDouble() * 0.8,
          ),
        );
        _controller.add(update);
        // occasionally emit an event
        if (_random.nextDouble() < 0.03) {
          final evt = TripEvent(
            id: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
            tripId: tripId,
            type: EventType.delayDetected,
            severity: EventSeverity.warning,
            message: 'Delay detected for $tripId',
            location: update.location,
          );
          ws?.pushEvent(evt);
        }
      }
    });
  }

  @override
  Stream<TripUpdate> subscribeTripUpdates() => _controller.stream;

  @override
  Future<void> cancelTrip(String tripId) async {
    // In mock, emit a final cancelled update
    _controller.add(
      TripUpdate(
        tripId: tripId,
        status: TripStatus.cancelled,
        progress: 0.0,
        location: null,
      ),
    );
  }

  @override
  Future<void> completeTrip(String tripId) async {
    _controller.add(
      TripUpdate(
        tripId: tripId,
        status: TripStatus.completed,
        progress: 1.0,
        location: null,
      ),
    );
  }

  @override
  Future<void> reassignDriver(String tripId, String driverId) async {
    // No-op in mock, but emit event
    ws?.pushEvent(
      TripEvent(
        id: 'EVT-${DateTime.now().microsecondsSinceEpoch}',
        tripId: tripId,
        type: EventType.incidentReported,
        severity: EventSeverity.info,
        message: 'Driver reassigned to $driverId',
      ),
    );
  }
}
