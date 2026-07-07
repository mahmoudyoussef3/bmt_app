import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 7, 7, 8);

  RouteStop stop(
    String name,
    int order,
    double lat, {
    double lng = 31.0,
    DateTime? arrival,
  }) => RouteStop(
    name: name,
    order: order,
    latitude: lat,
    longitude: lng,
    plannedArrival: arrival,
  );

  // Straight route, stops ~1112 m apart; planned times 15 min apart.
  List<RouteStop> stops() => [
    stop('A', 0, 30.00, arrival: t0),
    stop('B', 1, 30.01, arrival: t0.add(const Duration(minutes: 15))),
    stop('C', 2, 30.02, arrival: t0.add(const Duration(minutes: 30))),
    stop('D', 3, 30.03, arrival: t0.add(const Duration(minutes: 45))),
  ];

  RouteProgressEngine engine({
    TripProgressPhase phase = TripProgressPhase.enRoute,
  }) => RouteProgressEngine(stops: stops(), phase: phase);

  test('without any fix, ETAs fall back to the published schedule', () {
    final e = engine(phase: TripProgressPhase.headingToPickup);
    final s = e.snapshot(t0);
    expect(s.hasVehicleFix, isFalse);
    expect(s.routeFraction, 0);
    expect(s.nextStopIndex, 0);
    expect(s.stops[0].status, StopVisitStatus.next);
    expect(s.stops[2].etaConfidence, EtaConfidence.scheduled);
    expect(s.stops[2].eta, t0.add(const Duration(minutes: 30)));
  });

  test('heading to pickup: ETA to origin uses inflated direct distance', () {
    final e = engine(phase: TripProgressPhase.headingToPickup);
    // ~2224 m south of stop A, moving 40 km/h.
    e.addFix(latitude: 29.98, longitude: 31.0, speedKmh: 40, now: t0);
    final s = e.snapshot(t0);
    expect(s.routeFraction, 0);
    final origin = s.stops[0];
    expect(origin.status, StopVisitStatus.next);
    expect(origin.remainingMeters, closeTo(2224 * 1.3, 30));
    expect(origin.etaConfidence, EtaConfidence.live);
    expect(origin.eta!.isAfter(t0), isTrue);
  });

  test('boarding: reaching the origin marks it arrived', () {
    final e = engine(phase: TripProgressPhase.boarding);
    e.addFix(latitude: 30.0005, longitude: 31.0, speedKmh: 0, now: t0);
    expect(e.snapshot(t0).stops[0].status, StopVisitStatus.arrived);
  });

  test('en route: passed stops depart, progress and live ETAs flow', () {
    final e = engine();
    // Halfway between A and B, moving 60 km/h.
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 60, now: t0);
    final s = e.snapshot(t0);
    expect(s.stops[0].status, StopVisitStatus.departed);
    expect(s.stops[1].status, StopVisitStatus.next);
    expect(s.routeFraction, closeTo(556 / 3336, 0.01));
    // Destination: ~2780 m plus dwell at B and C (2 × 45 s).
    final destination = s.stops[3];
    expect(destination.etaConfidence, EtaConfidence.live);
    final seconds = destination.eta!.difference(t0).inSeconds;
    expect(seconds, closeTo(2780 / (60 / 3.6) + 90, 15));
  });

  test('arrival/departure hysteresis prevents flapping at a stop', () {
    final e = engine();
    e.addFix(latitude: 30.01, longitude: 31.0, speedKmh: 5, now: t0);
    expect(e.snapshot(t0).stops[1].status, StopVisitStatus.arrived);
    // 100 m of GPS drift: still inside the departure radius.
    e.addFix(latitude: 30.0109, longitude: 31.0, speedKmh: 0, now: t0);
    expect(e.snapshot(t0).stops[1].status, StopVisitStatus.arrived);
    // 330 m onward: genuinely departed.
    e.addFix(latitude: 30.013, longitude: 31.0, speedKmh: 40, now: t0);
    final s = e.snapshot(t0);
    expect(s.stops[1].status, StopVisitStatus.departed);
    expect(s.nextStopIndex, 2);
  });

  test('progress is monotonic: a backwards jitter fix cannot regress', () {
    final e = engine();
    e.addFix(latitude: 30.013, longitude: 31.0, speedKmh: 40, now: t0);
    final before = e.snapshot(t0);
    e.addFix(latitude: 30.011, longitude: 31.0, speedKmh: 40, now: t0);
    final after = e.snapshot(t0);
    expect(after.routeFraction, before.routeFraction);
    expect(after.stops[1].status, StopVisitStatus.departed);
  });

  test('off-route freezes progress and resumes on return', () {
    final e = engine();
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 50, now: t0);
    final onRoute = e.snapshot(t0).routeFraction;
    // ~960 m east of the corridor: off-route.
    e.addFix(latitude: 30.008, longitude: 31.01, speedKmh: 50, now: t0);
    final detour = e.snapshot(t0);
    expect(detour.isOffRoute, isTrue);
    expect(detour.routeFraction, onRoute);
    expect(detour.stops[1].etaConfidence, EtaConfidence.scheduled);
    // Back on the road further ahead.
    e.addFix(latitude: 30.015, longitude: 31.0, speedKmh: 50, now: t0);
    final resumed = e.snapshot(t0);
    expect(resumed.isOffRoute, isFalse);
    expect(resumed.routeFraction, greaterThan(onRoute));
  });

  test('stale GPS degrades ETAs to the schedule', () {
    final e = engine();
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 60, now: t0);
    final fresh = e.snapshot(t0.add(const Duration(minutes: 1)));
    expect(fresh.isStale, isFalse);
    expect(fresh.stops[3].etaConfidence, EtaConfidence.live);
    final stale = e.snapshot(t0.add(const Duration(minutes: 3)));
    expect(stale.isStale, isTrue);
    expect(stale.stops[3].etaConfidence, EtaConfidence.scheduled);
    expect(stale.stops[3].eta, t0.add(const Duration(minutes: 45)));
  });

  test('completion marks every stop departed and the route fully covered', () {
    final e = engine();
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 60, now: t0);
    e.updatePhase(TripProgressPhase.completed);
    final s = e.snapshot(t0);
    expect(s.routeFraction, 1);
    expect(s.nextStopIndex, isNull);
    expect(s.stops.every((p) => p.status == StopVisitStatus.departed), isTrue);
    expect(s.stops.every((p) => p.eta == null), isTrue);
  });

  test('seedVisited floors progress under sparse GPS', () {
    final e = engine();
    e.seedVisited(2); // Operational log says the bus reached B.
    final s = e.snapshot(t0);
    expect(s.stops[0].status, StopVisitStatus.departed);
    expect(s.stops[1].status, StopVisitStatus.arrived);
    expect(s.traveledMeters, closeTo(1112, 3));
  });

  test('degrades gracefully with no trackable route', () {
    final e = RouteProgressEngine(stops: [stops().first]);
    e.updatePhase(TripProgressPhase.enRoute);
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 60, now: t0);
    final s = e.snapshot(t0);
    expect(s.totalRouteMeters, 0);
    expect(s.routeFraction, 0);
    expect(s.stops.length, 1);
  });

  test('rider pickup lookup finds stops by name', () {
    final e = engine();
    e.addFix(latitude: 30.005, longitude: 31.0, speedKmh: 60, now: t0);
    final s = e.snapshot(t0);
    expect(s.stopByName(' c ')!.stop.name, 'C');
    expect(s.stopByName('unknown'), isNull);
    expect(s.stopByName(null), isNull);
  });
}
