import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_package_offer.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricable_package.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/presentation/widgets/trip_fare_controllers.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/usecases/trip_creation_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';

const _catalog = [
  TripPricablePackage(
    id: 'cat-week',
    name: 'أسبوع عمل',
    rideCount: 10,
    durationDays: 5,
  ),
  TripPricablePackage(
    id: 'cat-month',
    name: 'شهر عمل',
    rideCount: 44,
    durationDays: 30,
  ),
];

TripRoutePoint _point(String id, int order) =>
    TripRoutePoint(id: id, name: 'محطة $order', order: order);

OperationTrip _trip(String id) => OperationTrip(
  id: id,
  routeId: 'route-1',
  route: 'مسار',
  driverId: 'driver-1',
  driver: 'سائق',
  vehicleId: 'vehicle-1',
  vehicle: 'باص',
  date: '2026-08-20',
  departure: '08:00',
  arrival: '11:00',
  status: OperationTripStatus.scheduled,
  capacity: 14,
  ticketPrice: 100,
  currency: 'ج.م',
  routePoints: [_point('p1', 1), _point('p2', 2)],
  seats: const [],
  passengers: const [],
  events: const [],
  notes: const [],
);

/// Records what the planner asked the data layer to write, so the tests can
/// assert on the trip's package menu rather than on the UI that built it.
class _RecordingRepository implements TripsRepository {
  _RecordingRepository();

  final created = <TripPackageOffer>[];
  final pricing = <TripPricing>[];
  var _nextId = 0;

  @override
  Future<OperationTrip> createTrip(CreateTripInput input) async =>
      _trip('trip-1');

  @override
  Future<String> createTripPackage({
    required String tripId,
    required TripPackageOffer offer,
  }) async {
    created.add(offer);
    return 'new-${++_nextId}';
  }

  @override
  Future<TripPricing> upsertTripPricing(TripPricing row) async {
    pricing.add(row);
    return row;
  }

  @override
  Future<OperationTrip> getTripById(String tripId) async => _trip(tripId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TripFareControllers — the trip builds its own package menu', () {
    late TripFareControllers fare;

    setUp(() => fare = TripFareControllers(_catalog));
    tearDown(() => fare.dispose());

    test('a trip starts with nothing until packages are added to it', () {
      expect(fare.entries, isEmpty);
      expect(fare.offers, isEmpty);
      expect(fare.unusedCatalog.map((p) => p.id), ['cat-week', 'cat-month']);
    });

    test('seeding from the catalog is a starting point, not a rule', () {
      fare.baseFareController.text = '100';
      fare.seedFromCatalog();
      expect(fare.entries.length, 2);

      // The office drops the one it does not sell on this trip.
      fare.removeAt(0);
      expect(fare.entries.single.packageId, 'cat-month');
      expect(fare.packagePrices.keys, ['cat-month']);
      expect(fare.unusedCatalog.map((p) => p.id), ['cat-week']);
    });

    test('a package written here is priced and noted for this trip only', () {
      fare.baseFareController.text = '100';
      final entry = fare.addBlank();
      entry.name.text = 'أسبوع الجامعة';
      entry.rides.text = '6';
      entry.days.text = '7';
      entry.price.text = '400';
      entry.note.text = 'تشمل رحلة العودة بعد المحاضرة';

      final offer = fare.offers.single;
      expect(offer.needsCreating, isTrue);
      expect(offer.isTripScoped, isTrue);
      expect(offer.name, 'أسبوع الجامعة');
      expect(offer.rideCount, 6);
      expect(offer.durationDays, 7);
      expect(offer.price, 400);
      expect(offer.note, 'تشمل رحلة العودة بعد المحاضرة');

      // It has no id yet, so it cannot be written to trip_package_prices.
      expect(fare.packagePrices, isEmpty);
    });

    test('the base fare suggests prices but never overwrites a typed one', () {
      fare.seedFromCatalog();
      fare.baseFareController.text = '100';
      fare.syncPricesFromBase();
      final suggested = fare.entries.first.priceValue;
      expect(suggested, greaterThan(0));

      fare.entries.first.price.text = '600';
      fare.markPriceEdited(fare.entries.first);
      fare.baseFareController.text = '200';
      fare.syncPricesFromBase();

      expect(fare.entries.first.priceValue, 600);
      // The untouched one still follows the base fare.
      expect(fare.entries[1].priceValue, greaterThan(suggested));
    });

    test('a half-filled package blocks the save instead of vanishing', () {
      fare.baseFareController.text = '100';
      final entry = fare.addBlank();
      entry.name.text = 'باقة بلا سعر';

      expect(fare.hasIncompletePackage, isTrue);
      expect(fare.isValid, isFalse);
      expect(fare.offers, isEmpty);

      entry.rides.text = '5';
      entry.days.text = '7';
      entry.price.text = '350';
      expect(fare.hasIncompletePackage, isFalse);
      expect(fare.isValid, isTrue);
    });

    test('Arabic-Indic digits parse in every field, not just the fare', () {
      fare.baseFareController.text = '١٠٠';
      final entry = fare.addBlank();
      entry.name.text = 'باقة';
      entry.rides.text = '٦';
      entry.days.text = '٧';
      entry.price.text = '٤٠٠';

      expect(fare.baseFare, 100);
      expect(entry.rideCount, 6);
      expect(entry.durationDays, 7);
      expect(entry.priceValue, 400);
    });

    test('loadFrom lists only the packages this pair actually prices', () {
      final row = TripPricing(
        id: 'pricing-1',
        tripId: 'trip-1',
        fromPointId: 'p1',
        toPointId: 'p2',
        fromPointName: 'A',
        toPointName: 'B',
        fromPointOrder: 1,
        toPointOrder: 2,
        oneTimePrice: 120,
        packagePrices: const {'cat-month': 480},
        packageNotes: const {'cat-month': 'يشمل الجمعة'},
        currency: 'ج.م',
        isActive: true,
        createdAt: DateTime(2026, 8, 20),
        updatedAt: DateTime(2026, 8, 20),
      );
      fare.loadFrom(row);

      expect(fare.baseFare, 120);
      expect(fare.entries.single.packageId, 'cat-month');
      expect(fare.packagePrices, {'cat-month': 480.0});
      expect(fare.packageNotes, {'cat-month': 'يشمل الجمعة'});
    });

    test('adopting a created package keeps the typed price and note', () {
      final draft = fare.addBlank();
      draft.name.text = 'باقة الرحلة';
      draft.rides.text = '4';
      draft.days.text = '3';
      draft.price.text = '250';
      draft.note.text = 'مقعد بجوار الشباك';

      fare.adoptCreatedPackage(draft, 'pkg-created');

      expect(fare.entries.single.packageId, 'pkg-created');
      expect(fare.entries.single.isTripScoped, isTrue);
      expect(fare.packagePrices, {'pkg-created': 250.0});
      expect(fare.packageNotes, {'pkg-created': 'مقعد بجوار الشباك'});
    });
  });

  group('CreateTripUseCase — only the chosen menu is priced', () {
    test(
      'a written package is created against the trip, then priced',
      () async {
        final repo = _RecordingRepository();
        await CreateTripUseCase(repo)(
          const CreateTripInput(
            routeId: 'route-1',
            route: 'مسار',
            driverId: 'driver-1',
            driver: 'سائق',
            date: '2026-08-20',
            departure: '08:00',
            arrival: '11:00',
            ticketPrice: 100,
          ),
          const [],
          const [
            TripPackageOffer(
              packageId: '',
              name: 'أسبوع الجامعة',
              rideCount: 6,
              durationDays: 7,
              price: 400,
              note: 'تشمل رحلة العودة',
              isTripScoped: true,
            ),
          ],
        );

        expect(repo.created.single.name, 'أسبوع الجامعة');
        expect(repo.pricing.single.packagePrices, {'new-1': 400.0});
        expect(repo.pricing.single.packageNotes, {'new-1': 'تشمل رحلة العودة'});
      },
    );

    test(
      'a catalog package left off the trip is never priced onto it',
      () async {
        final repo = _RecordingRepository();
        await CreateTripUseCase(repo)(
          const CreateTripInput(
            routeId: 'route-1',
            route: 'مسار',
            driverId: 'driver-1',
            driver: 'سائق',
            date: '2026-08-20',
            departure: '08:00',
            arrival: '11:00',
            ticketPrice: 100,
          ),
          const [],
          const [
            TripPackageOffer(
              packageId: 'cat-month',
              name: 'شهر عمل',
              rideCount: 44,
              durationDays: 30,
              price: 900,
            ),
          ],
        );

        expect(repo.created, isEmpty);
        expect(repo.pricing.single.packagePrices, {'cat-month': 900.0});
        // The office's other catalog package was not offered here, so it gets
        // no price row — the old behaviour derived one for every package.
        expect(
          repo.pricing.single.packagePrices.containsKey('cat-week'),
          isFalse,
        );
      },
    );

    test(
      'an unsellable offer is dropped rather than written at zero',
      () async {
        final repo = _RecordingRepository();
        await CreateTripUseCase(repo)(
          const CreateTripInput(
            routeId: 'route-1',
            route: 'مسار',
            driverId: 'driver-1',
            driver: 'سائق',
            date: '2026-08-20',
            departure: '08:00',
            arrival: '11:00',
            ticketPrice: 100,
          ),
          const [],
          const [
            TripPackageOffer(
              packageId: '',
              name: 'بلا سعر',
              rideCount: 5,
              durationDays: 7,
              price: 0,
            ),
          ],
        );

        expect(repo.created, isEmpty);
        expect(repo.pricing.single.packagePrices, isEmpty);
      },
    );
  });
}
