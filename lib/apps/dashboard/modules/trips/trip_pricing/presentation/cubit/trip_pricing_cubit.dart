import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
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
  final bool isSaving;
  final String? error;

  const TripPricingLoaded({
    required this.pricing,
    this.isSaving = false,
    this.error,
  });

  TripPricingLoaded copyWith({
    List<TripPricing>? pricing,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TripPricingLoaded(
      pricing: pricing ?? this.pricing,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TripPricingCubit extends Cubit<TripPricingState> {
  final GetTripPricingUseCase _getTripPricing;
  final SaveTripPricingUseCase _saveTripPricing;
  final ToggleTripPricingUseCase _toggleTripPricing;

  TripPricingCubit({
    required GetTripPricingUseCase getTripPricing,
    required SaveTripPricingUseCase saveTripPricing,
    required ToggleTripPricingUseCase toggleTripPricing,
  }) : _getTripPricing = getTripPricing,
       _saveTripPricing = saveTripPricing,
       _toggleTripPricing = toggleTripPricing,
       super(const TripPricingInitial());

  Future<void> loadPricing(String tripId) async {
    emit(const TripPricingLoading());
    try {
      final list = await _getTripPricing(tripId);
      emit(TripPricingLoaded(pricing: list));
    } catch (e) {
      emit(TripPricingError(e.toString()));
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
      emit(TripPricingLoaded(pricing: list));
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
