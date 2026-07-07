import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RouteStop stop(String name, int order, double lat, [double lng = 31.0]) =>
      RouteStop(name: name, order: order, latitude: lat, longitude: lng);

  // Straight south→north line; 0.01° of latitude ≈ 1111.95 m.
  final line = [
    stop('A', 0, 30.00),
    stop('B', 1, 30.01),
    stop('C', 2, 30.02),
    stop('D', 3, 30.03),
  ];

  test('accumulates along-route distances per stop', () {
    final geometry = RouteGeometry(line);
    expect(geometry.cumulativeMeters[0], 0);
    expect(geometry.cumulativeMeters[1], closeTo(1112, 2));
    expect(geometry.cumulativeMeters[3], closeTo(3336, 5));
    expect(geometry.totalMeters, geometry.cumulativeMeters[3]);
    expect(geometry.isTrackable, isTrue);
  });

  test('drops stops without valid coordinates', () {
    final geometry = RouteGeometry([
      stop('A', 0, 30.00),
      stop('junk', 1, 0, 0),
      stop('B', 2, 30.01),
    ]);
    expect(geometry.stops.length, 2);
    expect(geometry.totalMeters, closeTo(1112, 2));
  });

  test('projects a position onto the route with along/cross distances', () {
    final geometry = RouteGeometry(line);
    final projection = geometry.project(30.005, 31.001)!;
    expect(projection.alongTrackMeters, closeTo(556, 2));
    // 0.001° of longitude at 30° N ≈ 96 m.
    expect(projection.crossTrackMeters, closeTo(96, 2));
    expect(projection.segmentIndex, 0);
  });

  test('clamps projections beyond segment ends to the vertices', () {
    final geometry = RouteGeometry(line);
    final before = geometry.project(29.99, 31.0)!;
    expect(before.alongTrackMeters, 0);
    final after = geometry.project(30.04, 31.0)!;
    expect(after.alongTrackMeters, closeTo(geometry.totalMeters, 1));
  });

  test('prefers forward matches when a route passes near itself', () {
    // Out-and-back route: D shadows A's position.
    final loop = [
      stop('A', 0, 30.00),
      stop('B', 1, 30.01),
      stop('C', 2, 30.01, 31.01),
      stop('D', 3, 30.0001, 31.01),
    ];
    final geometry = RouteGeometry(loop);
    // Near the shared area: without a floor it matches the first leg…
    final naive = geometry.project(30.0005, 31.0099)!;
    expect(naive.segmentIndex, 2);
    // …and with a floor deep into the route it must not snap backwards.
    final ahead = geometry.project(
      30.005,
      31.01,
      minAlongMeters: geometry.cumulativeMeters[2],
      backtrackToleranceMeters: 200,
    )!;
    expect(ahead.segmentIndex, 2);
    expect(ahead.alongTrackMeters,
        greaterThan(geometry.cumulativeMeters[2] - 200));
  });

  test('is not trackable with fewer than two valid stops', () {
    expect(RouteGeometry([stop('A', 0, 30.0)]).isTrackable, isFalse);
    expect(RouteGeometry(const []).isTrackable, isFalse);
    expect(RouteGeometry(const []).project(30, 31), isNull);
  });
}
