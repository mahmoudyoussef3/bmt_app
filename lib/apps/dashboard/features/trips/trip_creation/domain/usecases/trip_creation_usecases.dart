import 'package:bmt_app/core/pricing/package_tier_pricing.dart';

import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class CreateTripUseCase {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  Future<OperationTrip> call(
    CreateTripInput input,
    List<TripPricing> pricing,
  ) async {
    final trip = await _repository.createTrip(input);
    // `trip_pricing` is keyed by trip_route_point ids, which only exist once
    // the trip has snapshotted its route stations — so the fare configured in
    // the planner is expanded across the pairs here, not in the widget.
    final pricingRows = pricing.isNotEmpty
        ? pricing
        : _standardPricingFromTrip(trip, input);
    for (final p in pricingRows) {
      await _repository.upsertTripPricing(p.copyWith(tripId: trip.id));
    }
    return _repository.getTripById(trip.id);
  }

  /// Every boarding -> dropoff pair gets the operator's ticket price and the
  /// package tiers they configured next to it. A tier left blank falls back to
  /// the standard derivation rather than to the ticket price itself — copying
  /// the flat ticket price into every tier (the old behaviour) made a monthly
  /// subscription cost the same as a single ride in the Client app.
  List<TripPricing> _standardPricingFromTrip(
    OperationTrip trip,
    CreateTripInput input,
  ) {
    final points = trip.routePoints;
    final fare = input.ticketPrice;
    final now = DateTime.now();
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
            fiveDaysPrice: _tierPrice(input, PackageTierPricing.fiveDays),
            tenDaysPrice: _tierPrice(input, PackageTierPricing.tenDays),
            monthlyPrice: _tierPrice(input, PackageTierPricing.monthly),
            threeMonthsPrice: _tierPrice(input, PackageTierPricing.threeMonths),
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

  double _tierPrice(CreateTripInput input, PackageTier tier) {
    final configured = input.packageTierPrices[tier.key] ?? 0;
    if (configured > 0) return configured;
    return PackageTierPricing.priceFor(tier, input.ticketPrice);
  }
}

class GetActiveRoutesUseCase {
  final TripsRepository _repository;

  const GetActiveRoutesUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveRoutes();
  }
}

class GetActiveDriversUseCase {
  final TripsRepository _repository;

  const GetActiveDriversUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveDrivers();
  }
}

class GetActiveVehiclesUseCase {
  final TripsRepository _repository;

  const GetActiveVehiclesUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveVehicles();
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
