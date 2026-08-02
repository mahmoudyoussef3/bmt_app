import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/route_draft.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/services/route_identity.dart';
import 'package:bmt_app/core/geo/geo_models.dart';

GeoPlace _place(String label, double lat, double lng) =>
    GeoPlace(label: label, point: GeoPoint(lat, lng));

/// A draft with both endpoints resolved and totals filled in — the state a
/// route reaches right before it can be saved.
RouteDraft _readyDraft() {
  var draft = RouteDraft.blank(suggestedCode: 'RT-01');
  draft = draft.replaceStop(
    0,
    draft.origin.withPlace(_place('Banha, QL, Egypt', 30.46, 31.18)),
  );
  draft = draft.replaceStop(
    1,
    draft.destination.withPlace(
      _place('Smart Village, GZ, Egypt', 30.07, 31.02),
    ),
  );
  return draft.copyWith(distance: '42 كم', duration: '55 د');
}

void main() {
  group('RouteIdentity', () {
    test('keeps the human part of a geocoder label', () {
      expect(RouteIdentity.shortPlaceLabel('El-Marg, QH, Egypt'), 'El-Marg');
      expect(RouteIdentity.shortPlaceLabel('  بنها  '), 'بنها');
      expect(RouteIdentity.shortPlaceLabel(''), '');
    });

    test('reads the administrative area, falling back to the label', () {
      expect(RouteIdentity.areaFromLabel('El-Marg, QH, Egypt'), 'QH');
      expect(RouteIdentity.areaFromLabel('بنها'), 'بنها');
    });

    test('names a route after its endpoints, and only once both are known', () {
      expect(
        RouteIdentity.suggestName('Banha, QL, Egypt', 'Smart Village, GZ'),
        'Banha - Smart Village',
      );
      expect(RouteIdentity.suggestName('Banha', ''), '');
    });

    test('reserves the first free sequential code', () {
      expect(RouteIdentity.suggestCode(const []), 'RT-01');
      expect(RouteIdentity.suggestCode(const ['RT-01', 'RT-03']), 'RT-02');
      // Codes typed by hand before this existed ("new 1", "200") never collide
      // with the generated sequence.
      expect(RouteIdentity.suggestCode(const ['new 1', '200']), 'RT-01');
    });
  });

  group('RouteDraft', () {
    test('a blank draft is an origin and a destination, nothing else', () {
      final draft = RouteDraft.blank(suggestedCode: 'RT-01');

      expect(draft.stops, hasLength(2));
      expect(draft.intermediateStops, isEmpty);
      expect(draft.isEditing, isFalse);
      expect(draft.code, 'RT-01');
      expect(draft.isReady, isFalse);
    });

    test('reports the missing endpoint first, pointing at the stop', () {
      final draft = RouteDraft.blank(suggestedCode: 'RT-01');

      final first = draft.issues.first;
      expect(first.message, contains('نقطة الانطلاق'));
      expect(first.stopIndex, 0);
    });

    test('picking a place fills title, area and coordinates together', () {
      final stop = RouteDraft.blank(
        suggestedCode: 'RT-01',
      ).origin.withPlace(_place('El-Marg, QH, Egypt', 30.15, 31.33));

      expect(stop.name, 'El-Marg');
      expect(stop.area, 'QH');
      expect(stop.description, 'El-Marg, QH, Egypt');
      expect(stop.point, const GeoPoint(30.15, 31.33));
    });

    test('a named, located, measured route is ready to save', () {
      final draft = _readyDraft();

      expect(draft.issues, isEmpty);
      expect(draft.isReady, isTrue);
      expect(draft.name, 'Banha - Smart Village');
      expect(draft.usesSuggestedName, isTrue);
    });

    test('an operator-typed name wins over the suggestion', () {
      final draft = _readyDraft().copyWith(nameOverride: 'خط القاهرة السريع');

      expect(draft.name, 'خط القاهرة السريع');
      expect(draft.usesSuggestedName, isFalse);
    });

    test('two named places are enough — coordinates are not required', () {
      var draft = RouteDraft.blank(suggestedCode: 'RT-01');
      draft = draft.replaceStop(0, draft.origin.copyWith(name: 'بنها'));
      draft = draft.replaceStop(1, draft.destination.copyWith(name: 'القاهرة'));

      expect(draft.locatedStops, 0);
      expect(draft.hasMetrics, isFalse);
      expect(draft.issues, isEmpty);
      expect(draft.isReady, isTrue);
    });

    test('a stop with no location is still a saveable stop', () {
      final draft = _readyDraft().addStop();
      final withName = draft.replaceStop(
        1,
        draft.stops[1].copyWith(name: 'القناطر'),
      );

      expect(withName.stops[1].isLocated, isFalse);
      expect(withName.stops[1].isComplete, isTrue);
      expect(withName.isReady, isTrue);
      expect(withName.toRoute().stations[1].latitude, isNull);
    });

    test('an unnamed stop is the one thing that blocks the save', () {
      final draft = _readyDraft().addStop();

      expect(draft.isReady, isFalse);
      final issue = draft.issues.first;
      expect(issue.message, contains('بدون اسم'));
      expect(issue.stopIndex, 1);
    });

    test('the same place at both ends is rejected', () {
      var draft = RouteDraft.blank(suggestedCode: 'RT-01');
      draft = draft.replaceStop(0, draft.origin.copyWith(name: 'بنها'));
      draft = draft.replaceStop(1, draft.destination.copyWith(name: 'بنها'));

      expect(draft.endpointsCollide, isTrue);
      expect(draft.isReady, isFalse);
      expect(draft.issues.first.message, contains('نفس المكان'));
    });

    test('a located point can drop its coordinates and stay valid', () {
      final draft = _readyDraft();
      final cleared = draft.replaceStop(0, draft.origin.withoutPoint());

      expect(cleared.origin.isLocated, isFalse);
      expect(cleared.origin.name, 'Banha');
      expect(cleared.isReady, isTrue);
      expect(cleared.orderedPoints, isEmpty);
    });

    test('new stops land before the destination', () {
      final draft = _readyDraft().addStop();

      expect(draft.stops, hasLength(3));
      expect(draft.destination.name, 'Smart Village');
      expect(draft.intermediateStops.single.index, 1);
    });

    test(
      'a stop can be inserted into a chosen gap, never onto an endpoint',
      () {
        var draft = _readyDraft().addStopAt(
          1,
          stop: RouteStopDraft(key: 'a', name: 'أولى'),
        );
        draft = draft.addStopAt(
          1,
          stop: RouteStopDraft(key: 'b', name: 'قبلها'),
        );

        expect(draft.stops.map((stop) => stop.name).toList(), [
          'Banha',
          'قبلها',
          'أولى',
          'Smart Village',
        ]);

        // Index 0 and anything past the destination clamp inside the endpoints.
        final clamped = draft.addStopAt(
          0,
          stop: RouteStopDraft(key: 'c', name: 'س'),
        );
        expect(clamped.origin.name, 'Banha');
        final atEnd = draft.addStopAt(
          99,
          stop: RouteStopDraft(key: 'd', name: 'ص'),
        );
        expect(atEnd.destination.name, 'Smart Village');
      },
    );

    test('the direction reads as a chain of the named places', () {
      final draft = _readyDraft().addStopAt(
        1,
        stop: RouteStopDraft(key: 'a', name: 'القناطر'),
      );

      expect(draft.directionLabel, 'Banha ← القناطر ← Smart Village');
    });

    test('the return leg is a new route with the stops reversed', () {
      var draft = _readyDraft().addStopAt(
        1,
        stop: RouteStopDraft(key: 'a', id: 'station-2', name: 'القناطر'),
      );
      draft = draft.copyWith(id: 'route-1');

      final back = draft.reversedLeg(suggestedCode: 'RT-08');

      expect(back.isEditing, isFalse, reason: 'never overwrites the outbound');
      expect(back.stops.map((stop) => stop.name).toList(), [
        'Smart Village',
        'القناطر',
        'Banha',
      ]);
      // Saved-row ids are dropped, so saving inserts new stations rather than
      // moving the outbound route's rows onto the return leg.
      expect(back.stops.every((stop) => stop.id.isEmpty), isTrue);
      expect(back.code, 'RT-08');
      // The old offsets described the other order and would be wrong here.
      expect(back.stops.every((stop) => stop.arrivalOffset.isEmpty), isTrue);
    });

    test('endpoints cannot be removed or dragged out of place', () {
      final draft = _readyDraft().addStop();

      expect(draft.removeStop(0).stops, hasLength(3));
      expect(draft.removeStop(2).stops, hasLength(3));
      expect(draft.removeStop(1).stops, hasLength(2));
      expect(draft.moveStop(0, 2).stops.first.name, 'Banha');
    });

    test('reorders intermediate stops with list-drag semantics', () {
      var draft = _readyDraft().addStop().addStop();
      draft = draft.replaceStop(1, draft.stops[1].copyWith(name: 'أولى'));
      draft = draft.replaceStop(2, draft.stops[2].copyWith(name: 'ثانية'));

      final moved = draft.moveStop(1, 3);

      expect(moved.stops.map((stop) => stop.name).toList(), [
        'Banha',
        'ثانية',
        'أولى',
        'Smart Village',
      ]);
    });

    test('toRoute numbers stations, shortens cities and maps boarding', () {
      var draft = _readyDraft().addStop();
      draft = draft.replaceStop(
        1,
        draft.stops[1]
            .withPlace(_place('Qalyub, QL, Egypt', 30.18, 31.20))
            .copyWith(boarding: RouteStopBoarding.pickupOnly),
      );

      final route = draft.toRoute();

      expect(route.stations.map((station) => station.order).toList(), [
        1,
        2,
        3,
      ]);
      expect(route.startCity, 'Banha');
      expect(route.endCity, 'Smart Village');
      expect(route.stations[1].pickupAllowed, isTrue);
      expect(route.stations[1].dropoffAllowed, isFalse);
      expect(route.stations[1].latitude, 30.18);
      expect(route.routeCode, 'RT-01');
    });

    test('round-trips a saved route, rebuilding dwell from its offsets', () {
      const saved = OperationRoute(
        id: 'route-1',
        routeCode: 'RT-09',
        name: 'بنها - القرية الذكية',
        startCity: 'بنها',
        endCity: 'القرية الذكية',
        duration: '1 س 10 د',
        distance: '62 كم',
        status: OperationRouteStatus.active,
        stations: [
          RouteStation(
            id: 'station-1',
            name: 'بنها',
            area: 'القليوبية',
            arrivalOffset: '00:00',
            departureOffset: '00:00',
            order: 1,
          ),
          RouteStation(
            id: 'station-2',
            name: 'القناطر',
            area: 'القليوبية',
            arrivalOffset: '00:20',
            departureOffset: '00:25',
            latitude: 30.18,
            longitude: 31.13,
            pickupAllowed: false,
            dropoffAllowed: true,
            order: 2,
          ),
        ],
        notes: ['ملاحظة'],
      );

      final draft = RouteDraft.fromRoute(saved);

      expect(draft.isEditing, isTrue);
      expect(draft.stops, hasLength(2));
      expect(draft.stops[1].dwellMinutes, 5);
      expect(draft.stops[1].boarding, RouteStopBoarding.dropoffOnly);
      // Existing station ids survive the round trip, so a save updates rows
      // instead of duplicating them.
      expect(draft.toRoute().stations[1].id, 'station-2');
      expect(draft.toRoute().notes, ['ملاحظة']);
    });

    test('an archived route opens as paused so it can be edited', () {
      const archived = OperationRoute(
        id: 'route-2',
        name: 'مسار',
        startCity: 'أ',
        endCity: 'ب',
        duration: '',
        distance: '',
        status: OperationRouteStatus.archived,
        stations: [],
        notes: [],
      );

      final draft = RouteDraft.fromRoute(archived);

      expect(draft.status, OperationRouteStatus.paused);
      // Padded up to an origin and a destination even though it had none.
      expect(draft.stops, hasLength(2));
    });

    test('writes the computed schedule onto the stops in order', () {
      final draft = _readyDraft().withSchedule([
        (arrival: '00:00', departure: '00:00'),
        (arrival: '00:55', departure: '00:55'),
      ]);

      expect(draft.origin.departureOffset, '00:00');
      expect(draft.destination.arrivalOffset, '00:55');
      expect(draft.toRoute().stations.last.estimatedArrivalTime, '00:55');
    });
  });
}
