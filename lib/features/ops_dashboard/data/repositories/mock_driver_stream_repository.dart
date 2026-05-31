import 'dart:async';
import 'dart:math';
import '../../domain/models/driver_position.dart';
import '../../domain/models/position.dart';
import '../../domain/models/driver.dart';
import '../../domain/repositories/driver_stream_repository.dart';

class MockDriverStreamRepository implements DriverStreamRepository {
  final _controller = StreamController<DriverPosition>.broadcast();
  Timer? _timer;
  final _random = Random();

  MockDriverStreamRepository() {
    _start();
  }

  void _start() {
    final drivers = List.generate(10, (i) => 'DRIVER-${i + 1}');
    final positions = {
      for (var d in drivers)
        d: Position(
          lat: 0.1 + _random.nextDouble() * 0.8,
          lng: 0.1 + _random.nextDouble() * 0.8,
        ),
    };

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (var d in drivers) {
        final p = positions[d]!;
        final newP = Position(
          lat: (p.lat + (_random.nextDouble() - 0.5) * 0.01).clamp(0.0, 1.0),
          lng: (p.lng + (_random.nextDouble() - 0.5) * 0.01).clamp(0.0, 1.0),
        );
        positions[d] = newP;
        final status = _random.nextDouble() < 0.1
            ? DriverStatus.onTrip
            : DriverStatus.online;
        _controller.add(
          DriverPosition(driverId: d, position: newP, status: status),
        );
      }
    });
  }

  @override
  Stream<DriverPosition> subscribeDriverUpdates() => _controller.stream;
}
