import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/route_stop.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/domain/services/route_catalog_search.dart';

List<RouteStop> _stops(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    RouteStop(id: 's${i + 1}', name: names[i], order: i + 1),
];

RouteSummary _route({
  required String id,
  required String name,
  required String start,
  required String end,
  List<String> stops = const [],
  String office = 'Nile Express',
}) {
  return RouteSummary(
    id: id,
    name: name,
    startCity: start,
    endCity: end,
    officeName: office,
    stops: _stops(stops),
  );
}

/// Cairo → Mansoura, stopping at Shibin El Kom, Banha and Tanta on the way.
final _cairoMansoura = _route(
  id: 'A',
  name: 'Cairo Express',
  start: 'Cairo',
  end: 'Mansoura',
  stops: ['Cairo', 'Shibin El Kom', 'Banha', 'Tanta', 'Mansoura'],
);

/// Cairo → Zagazig, which shares only its origin with route A.
final _cairoZagazig = _route(
  id: 'B',
  name: 'Sharqia Line',
  start: 'Cairo',
  end: 'Zagazig',
  stops: ['Cairo', 'Shibin', 'Zagazig'],
  office: 'Delta Lines',
);

final _catalog = [_cairoMansoura, _cairoZagazig];

List<String> _ids(String query) => [
  for (final match in RouteCatalogSearch.apply(_catalog, query)) match.route.id,
];

void main() {
  group('RouteCatalogSearch matching', () {
    test('an empty query returns the whole catalog, uncaptioned', () {
      final matches = RouteCatalogSearch.apply(_catalog, '');

      expect(matches, hasLength(2));
      expect(matches.every((match) => match.isVia), isFalse);
    });

    test('a whitespace-only query is the same as no query', () {
      expect(RouteCatalogSearch.apply(_catalog, '   '), hasLength(2));
    });

    test('the origin still matches', () {
      expect(_ids('Cairo'), ['A', 'B']);
    });

    test('the destination still matches', () {
      expect(_ids('Mansoura'), ['A']);
    });

    test('an intermediate station matches its route', () {
      expect(_ids('Banha'), ['A']);
    });

    test('a station on no route matches nothing', () {
      expect(_ids('Alexandria'), isEmpty);
    });

    test('the route name and the operating office still match', () {
      expect(_ids('sharqia'), ['B']);
      expect(_ids('delta lines'), ['B']);
    });

    test('matching is case-insensitive and tolerates stray spaces', () {
      expect(_ids('BANHA'), ['A']);
      expect(_ids('  banha  '), ['A']);
    });

    test('a partial station name matches', () {
      expect(_ids('shib'), ['A', 'B']);
    });
  });

  group('RouteCatalogSearch match reasons', () {
    test('an intermediate hit is captioned with the station', () {
      final match = RouteCatalogSearch.apply(_catalog, 'banha').single;

      expect(match.isVia, isTrue);
      expect(match.viaStop, 'Banha');
    });

    test('an endpoint hit is never captioned as a stop along the way', () {
      for (final match in RouteCatalogSearch.apply(_catalog, 'cairo')) {
        expect(match.isVia, isFalse);
      }
    });

    test('a terminal station reads as an endpoint, not a way point', () {
      // The first stop is Cairo's terminal under its own name, so a hit on it
      // is a hit on the origin — nothing to caption.
      final route = _route(
        id: 'C',
        name: 'Coast Line',
        start: 'Cairo',
        end: 'Alexandria',
        stops: ['Ramses Station', 'Banha', 'Sidi Gaber'],
      );

      final match = RouteCatalogSearch.apply([route], 'ramses').single;

      expect(match.route.id, 'C');
      expect(match.isVia, isFalse);
    });

    test('a station repeated on one route is captioned once', () {
      final loop = _route(
        id: 'D',
        name: 'Ring Line',
        start: 'Cairo',
        end: 'Cairo',
        stops: ['Cairo', 'Banha', 'Tanta', 'Banha', 'Cairo'],
      );

      final matches = RouteCatalogSearch.apply([loop], 'banha');

      expect(matches, hasLength(1));
      expect(matches.single.viaStop, 'Banha');
    });
  });

  group('RouteCatalogSearch in Arabic', () {
    final route = _route(
      id: 'E',
      name: 'خط القاهرة المنصورة',
      start: 'القاهرة',
      end: 'المنصورة',
      stops: ['القاهرة', 'بنها', 'طنطا', 'المنصورة'],
      office: 'شركة الدلتا',
    );

    test('an intermediate Arabic station matches', () {
      final match = RouteCatalogSearch.apply([route], 'بنها').single;

      expect(match.viaStop, 'بنها');
    });

    test('spelling variants of one place still meet', () {
      // Definite article, ta marbuta and hamza forms are folded away.
      expect(RouteCatalogSearch.apply([route], 'منصوره'), hasLength(1));
      expect(RouteCatalogSearch.apply([route], 'القاهره'), hasLength(1));
    });

    test('a place on no route still matches nothing', () {
      expect(RouteCatalogSearch.apply([route], 'أسوان'), isEmpty);
    });
  });

  group('RouteCatalogSearch with incomplete data', () {
    test('a route with no stations is matched on its endpoints alone', () {
      final bare = _route(
        id: 'F',
        name: 'Coastal Line',
        start: 'Cairo',
        end: 'Marsa Matrouh',
      );

      expect(RouteCatalogSearch.apply([bare], 'matrouh'), hasLength(1));
      expect(RouteCatalogSearch.apply([bare], 'banha'), isEmpty);
    });

    test('blank station names are skipped rather than matched', () {
      final gappy = _route(
        id: 'G',
        name: 'Gappy Line',
        start: 'Cairo',
        end: 'Suez',
        stops: ['Cairo', '   ', 'Banha', 'Suez'],
      );

      expect(
        RouteCatalogSearch.apply([gappy], 'banha').single.viaStop,
        'Banha',
      );
      // Punctuation alone normalizes to nothing, which is "no search" — not a
      // needle that every blank name happens to contain.
      expect(RouteCatalogSearch.apply([gappy], '#'), hasLength(1));
      expect(RouteCatalogSearch.apply([gappy], '#').single.isVia, isFalse);
    });

    test('a route with empty endpoints does not throw', () {
      final blank = RouteSummary(
        id: 'H',
        name: '',
        startCity: '',
        endCity: '',
        stops: _stops(const ['', 'Banha', '']),
      );

      expect(
        RouteCatalogSearch.apply([blank], 'banha').single.viaStop,
        'Banha',
      );
      expect(RouteCatalogSearch.apply([blank], 'cairo'), isEmpty);
    });
  });
}
