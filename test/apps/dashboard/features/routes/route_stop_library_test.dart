import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/route_draft.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/services/route_stop_library.dart';
import 'package:bmt_app/core/geo/geo_models.dart';

RouteStation _station(
  String name, {
  String area = '',
  String description = '',
  double? lat,
  double? lng,
  bool pickup = true,
  bool dropoff = true,
  int order = 1,
}) {
  return RouteStation(
    id: 'st-$name-$order',
    name: name,
    area: area,
    arrivalOffset: '',
    locationDescription: description,
    latitude: lat,
    longitude: lng,
    pickupAllowed: pickup,
    dropoffAllowed: dropoff,
    order: order,
  );
}

OperationRoute _route(String id, List<RouteStation> stations) {
  return OperationRoute(
    id: id,
    name: id,
    startCity: '',
    endCity: '',
    duration: '',
    distance: '',
    status: OperationRouteStatus.active,
    stations: stations,
    notes: const [],
  );
}

void main() {
  group('normalize', () {
    test('folds the spellings that make one Egyptian place look like four', () {
      const canonical = 'شبين القناطر';
      for (final variant in [
        'شبين القناطر',
        'شبين  القناطر ',
        'شبيـن القناطر', // tatweel
        'شَبين القناطر', // harakat
      ]) {
        expect(
          RouteStopLibrary.normalize(variant),
          RouteStopLibrary.normalize(canonical),
          reason: variant,
        );
      }
    });

    test('unifies hamza forms, ta marbuta and alef maqsura', () {
      expect(
        RouteStopLibrary.normalize('أسيوط'),
        RouteStopLibrary.normalize('اسيوط'),
      );
      expect(
        RouteStopLibrary.normalize('المنصورة'),
        RouteStopLibrary.normalize('المنصوره'),
      );
      expect(
        RouteStopLibrary.normalize('مصطفى'),
        RouteStopLibrary.normalize('مصطفي'),
      );
    });

    test('drops the definite article so "المرج" and "مرج" are one place', () {
      expect(
        RouteStopLibrary.normalize('المرج'),
        RouteStopLibrary.normalize('مرج'),
      );
      expect(
        RouteStopLibrary.normalize('El Marg'),
        RouteStopLibrary.normalize('marg'),
      );
    });

    test('reads Arabic-Indic digits as their Western equivalents', () {
      expect(RouteStopLibrary.normalize('طريق ٦ اكتوبر'), 'طريق 6 اكتوبر');
    });
  });

  group('fromRoutes', () {
    test('collapses the same place used on several routes into one entry', () {
      final library = RouteStopLibrary.fromRoutes([
        _route('r1', [
          _station('شبين القناطر', area: 'القليوبية'),
          _station('القاهرة', order: 2),
        ]),
        _route('r2', [
          // Same place, spelled with a hamza-less alef and extra spaces.
          _station('شبين  القناطر ', lat: 30.31, lng: 31.32),
        ]),
      ]);

      final shibin = library.stops.firstWhere(
        (stop) => stop.name.startsWith('شبين'),
      );
      expect(library.stops, hasLength(2));
      expect(shibin.usageCount, 2);
      // The first spelling wins as the label; a later duplicate contributes
      // the coordinates the first one lacked.
      expect(shibin.name, 'شبين القناطر');
      expect(shibin.area, 'القليوبية');
      expect(shibin.point, const GeoPoint(30.31, 31.32));
    });

    test('ranks the most-used stops first', () {
      final library = RouteStopLibrary.fromRoutes([
        _route('r1', [_station('رمسيس'), _station('بنها', order: 2)]),
        _route('r2', [_station('رمسيس')]),
        _route('r3', [_station('رمسيس')]),
      ]);

      expect(library.stops.first.name, 'رمسيس');
      expect(library.stops.first.usageCount, 3);
    });

    test('ignores stops with no usable name', () {
      final library = RouteStopLibrary.fromRoutes([
        _route('r1', [_station('  '), _station('بنها', order: 2)]),
      ]);

      expect(library.stops.map((stop) => stop.name).toList(), ['بنها']);
    });
  });

  group('search', () {
    final library = RouteStopLibrary.fromRoutes([
      _route('r1', [
        _station('شبين القناطر', area: 'القليوبية'),
        _station('المرج', description: 'El-Marg, QH, Egypt', order: 2),
        _station('مسطرد', order: 3),
      ]),
    ]);

    test('an empty query offers the most-used stops', () {
      expect(library.search(''), hasLength(3));
    });

    test('matches partial names regardless of spelling', () {
      expect(library.search('شبين').single.name, 'شبين القناطر');
      expect(library.search('قناطر').single.name, 'شبين القناطر');
      // Without the definite article, and with a hamza the operator typed.
      expect(library.search('مرج').single.name, 'المرج');
    });

    test('matches the area and the saved address too', () {
      expect(library.search('القليوبية').single.name, 'شبين القناطر');
      // The geocoder writes Latin addresses, so a Latin query finds the stop
      // whose address it filled in.
      expect(library.search('El-Marg').single.name, 'المرج');
    });

    test('prefix matches rank above mid-word ones', () {
      final busy = RouteStopLibrary.fromRoutes([
        _route('r1', [
          _station('موقف مسطرد', order: 1),
          _station('مسطرد', order: 2),
        ]),
      ]);

      expect(busy.search('مسطرد').first.name, 'مسطرد');
    });

    test('an unknown place matches nothing — the operator just types it', () {
      expect(library.search('طنطا'), isEmpty);
    });
  });

  test('a suggestion becomes a stop without carrying its database row', () {
    final library = RouteStopLibrary.fromRoutes([
      _route('r1', [
        _station(
          'مسطرد',
          area: 'القليوبية',
          lat: 30.15,
          lng: 31.30,
          pickup: true,
          dropoff: false,
        ),
      ]),
    ]);

    final stop = library.stops.single.toStop('local-key');

    expect(stop.key, 'local-key');
    expect(stop.id, isEmpty);
    expect(stop.name, 'مسطرد');
    expect(stop.point, const GeoPoint(30.15, 31.30));
    expect(stop.boarding, RouteStopBoarding.pickupOnly);
  });
}
