import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_package_offer.dart';
import '../../../shared/domain/entities/trip_pricable_package.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';
import '../entities/trip_driver_option.dart';

class CreateTripUseCase {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  /// [offers] is the package menu the operator built for this trip in the
  /// planner's fare panel: catalog packages they picked, packages they wrote
  /// from scratch, or none at all. Whatever is not in that list is simply not
  /// sold on this trip — an office is never priced into a catalog template it
  /// did not choose.
  Future<OperationTrip> call(
    CreateTripInput input,
    List<TripPricing> pricing,
    List<TripPackageOffer> offers,
  ) async {
    final trip = await _repository.createTrip(input);

    // A package the operator invented here does not exist yet: create it
    // against this trip first, so every pricing row below can key on a real
    // `transport_packages.id`.
    final resolved = <TripPackageOffer>[];
    for (final offer in offers.where((offer) => offer.isSellable)) {
      if (!offer.needsCreating) {
        resolved.add(offer);
        continue;
      }
      final id = await _repository.createTripPackage(
        tripId: trip.id,
        offer: offer,
      );
      resolved.add(offer.copyWith(packageId: id));
    }

    final pricingRows = pricing.isNotEmpty
        ? pricing
        : _standardPricingFromTrip(trip, input, resolved);
    for (final p in pricingRows) {
      await _repository.upsertTripPricing(p.copyWith(tripId: trip.id));
    }
    return _repository.getTripById(trip.id);
  }

  /// Every boarding -> dropoff pair gets the operator's ticket price and the
  /// package menu they configured next to it — the same price and the same
  /// note on every pair, which is what the planner's single fare panel means.
  /// Per-pair differences are made afterwards in the Trip Pricing tab.
  List<TripPricing> _standardPricingFromTrip(
    OperationTrip trip,
    CreateTripInput input,
    List<TripPackageOffer> offers,
  ) {
    final points = trip.routePoints;
    final fare = input.ticketPrice;
    final now = DateTime.now();
    final packagePrices = {
      for (final offer in offers) offer.packageId: offer.price,
    };
    final packageNotes = {
      for (final offer in offers)
        if (offer.note.trim().isNotEmpty) offer.packageId: offer.note.trim(),
    };
    final rows = <TripPricing>[];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        rows.add(
          TripPricing(
            id: '',
            tripId: trip.id,
            fromPointId: points[i].id,
            toPointId: points[j].id,
            fromPointName: points[i].name,
            toPointName: points[j].name,
            fromPointOrder: points[i].order,
            toPointOrder: points[j].order,
            oneTimePrice: fare,
            packagePrices: packagePrices,
            packageNotes: packageNotes,
            currency: input.currency,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }
    return rows;
  }
}

class GetActiveRoutesUseCase {
  final TripsRepository _repository;

  const GetActiveRoutesUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveRoutes();
  }
}

/// The drivers the operator may schedule, each with the vehicle they operate.
///
/// There is no `GetActiveVehiclesUseCase` any more, on purpose. Trip creation is a
/// single resource choice — the driver — and the vehicle follows from the office's
/// driver↔vehicle assignment. Offering the fleet as a second, independent list is what
/// allowed a driver to be dispatched onto a bus that is not theirs.
class GetActiveDriversUseCase {
  final TripsRepository _repository;

  const GetActiveDriversUseCase(this._repository);

  Future<List<TripDriverOption>> call() {
    return _repository.getActiveDrivers();
  }
}

/// The office's saved catalog packages, offered as templates in the trip
/// planner's fare panel. The operator adds the ones they want to this trip —
/// or writes a package that exists nowhere else.
class GetOfficePricablePackagesUseCase {
  final TripsRepository _repository;

  const GetOfficePricablePackagesUseCase(this._repository);

  Future<List<TripPricablePackage>> call() {
    return _repository.getOfficePricablePackages();
  }
}

/// The packages that belong to one trip alone, for that trip's pricing tab.
class GetTripScopedPackagesUseCase {
  final TripsRepository _repository;

  const GetTripScopedPackagesUseCase(this._repository);

  Future<List<TripPricablePackage>> call(String tripId) {
    return _repository.getTripScopedPackages(tripId);
  }
}

/// Creates a package sold only on one trip. Used by the pricing editor when
/// the operator adds a package to a trip that already exists.
class CreateTripPackageUseCase {
  final TripsRepository _repository;

  const CreateTripPackageUseCase(this._repository);

  Future<String> call(String tripId, TripPackageOffer offer) {
    return _repository.createTripPackage(tripId: tripId, offer: offer);
  }
}

class GetResourceConflictsUseCase {
  final TripsRepository _repository;

  const GetResourceConflictsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) {
    return _repository.getResourceConflicts(
      date: date,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
    );
  }
}
