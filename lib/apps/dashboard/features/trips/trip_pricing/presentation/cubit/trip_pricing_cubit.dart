import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/trip_package_offer.dart';
import '../../../shared/domain/entities/trip_pricable_package.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_creation/domain/usecases/trip_creation_usecases.dart';
import '../../domain/usecases/trip_pricing_usecases.dart';

sealed class TripPricingState {
  const TripPricingState();
}

class TripPricingInitial extends TripPricingState {
  const TripPricingInitial();
}

class TripPricingLoading extends TripPricingState {
  const TripPricingLoading();
}

class TripPricingError extends TripPricingState {
  final String message;
  const TripPricingError(this.message);
}

class TripPricingLoaded extends TripPricingState {
  final List<TripPricing> pricing;

  /// Every package this trip's fare editor may offer: the office's catalog
  /// templates plus the packages created for this trip alone.
  final List<TripPricablePackage> packages;
  final bool isSaving;
  final String? error;

  const TripPricingLoaded({
    required this.pricing,
    required this.packages,
    this.isSaving = false,
    this.error,
  });

  TripPricingLoaded copyWith({
    List<TripPricing>? pricing,
    List<TripPricablePackage>? packages,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TripPricingLoaded(
      pricing: pricing ?? this.pricing,
      packages: packages ?? this.packages,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TripPricingCubit extends Cubit<TripPricingState> {
  final GetTripPricingUseCase _getTripPricing;
  final SaveTripPricingUseCase _saveTripPricing;
  final ToggleTripPricingUseCase _toggleTripPricing;
  final GetOfficePricablePackagesUseCase _getPricablePackages;
  final GetTripScopedPackagesUseCase _getTripScopedPackages;
  final CreateTripPackageUseCase _createTripPackage;

  TripPricingCubit({
    required GetTripPricingUseCase getTripPricing,
    required SaveTripPricingUseCase saveTripPricing,
    required ToggleTripPricingUseCase toggleTripPricing,
    required GetOfficePricablePackagesUseCase getPricablePackages,
    required GetTripScopedPackagesUseCase getTripScopedPackages,
    required CreateTripPackageUseCase createTripPackage,
  }) : _getTripPricing = getTripPricing,
       _saveTripPricing = saveTripPricing,
       _toggleTripPricing = toggleTripPricing,
       _getPricablePackages = getPricablePackages,
       _getTripScopedPackages = getTripScopedPackages,
       _createTripPackage = createTripPackage,
       super(const TripPricingInitial());

  /// The trip's own packages come back alongside the office catalog, so the
  /// pricing editor lists everything this trip may sell in one menu — a
  /// package invented for this trip is not in the catalog and would otherwise
  /// be invisible here.
  Future<void> loadPricing(String tripId) async {
    emit(const TripPricingLoading());
    try {
      final results = await Future.wait([
        _getTripPricing(tripId),
        _getPricablePackages(),
        _getTripScopedPackages(tripId),
      ]);
      emit(
        TripPricingLoaded(
          pricing: results[0] as List<TripPricing>,
          packages: [
            ...results[1] as List<TripPricablePackage>,
            ...results[2] as List<TripPricablePackage>,
          ],
        ),
      );
    } catch (e) {
      emit(TripPricingError(e.toString()));
    }
  }

  /// Creates a package sold only on [tripId] and folds it into the loaded
  /// package list, so the editor can price it in the same save. Returns its
  /// new id, or null when the write failed (the error is surfaced on state).
  Future<String?> createTripPackage(
    String tripId,
    TripPackageOffer offer,
  ) async {
    final current = state;
    try {
      final id = await _createTripPackage(tripId, offer);
      if (current is TripPricingLoaded) {
        emit(
          current.copyWith(
            packages: [
              ...current.packages,
              TripPricablePackage(
                id: id,
                name: offer.name,
                rideCount: offer.rideCount,
                durationDays: offer.durationDays,
                isTripScoped: true,
              ),
            ],
          ),
        );
      }
      return id;
    } catch (e) {
      if (current is TripPricingLoaded) {
        emit(current.copyWith(error: e.toString()));
      }
      return null;
    }
  }

  Future<String?> savePricing(TripPricing pricingData) async {
    final current = state;
    if (current is! TripPricingLoaded) return 'الحالة غير محملة';
    emit(current.copyWith(isSaving: true, clearError: true));
    try {
      final saved = await _saveTripPricing(pricingData);
      final List<TripPricing> list =
          <TripPricing>[
            saved,
            ...current.pricing.where((p) => p.id != saved.id),
          ]..sort((a, b) {
            final fromOrder = a.fromPointOrder.compareTo(b.fromPointOrder);
            if (fromOrder != 0) return fromOrder;
            return a.toPointOrder.compareTo(b.toPointOrder);
          });
      emit(TripPricingLoaded(pricing: list, packages: current.packages));
      return null;
    } catch (e) {
      emit(current.copyWith(isSaving: false, error: e.toString()));
      return e.toString();
    }
  }

  Future<void> togglePricingStatus(TripPricing pricingData) async {
    final current = state;
    if (current is! TripPricingLoaded) return;
    try {
      final updated = await _toggleTripPricing(
        pricingData.id,
        !pricingData.isActive,
      );
      final List<TripPricing> list = current.pricing
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      emit(current.copyWith(pricing: list));
    } catch (e) {
      emit(current.copyWith(error: e.toString()));
    }
  }
}
