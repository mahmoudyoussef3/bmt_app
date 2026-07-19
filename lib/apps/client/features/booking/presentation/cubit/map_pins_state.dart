import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';

sealed class MapPinsState {
  const MapPinsState();
}

class MapPinsLoading extends MapPinsState {
  const MapPinsLoading();
}

class MapPinsLoaded extends MapPinsState {
  const MapPinsLoaded({
    required this.query,
    required this.pickupPins,
    required this.destinationPins,
    this.selectedPickup,
    this.selectedDestination,
  });

  final BookingSearchQuery query;
  final List<MapPinOption> pickupPins;
  final List<MapPinOption> destinationPins;
  final MapPinOption? selectedPickup;
  final MapPinOption? selectedDestination;

  bool get canConfirm => query.isComplete;

  MapPinsLoaded copyWith({
    BookingSearchQuery? query,
    List<MapPinOption>? pickupPins,
    List<MapPinOption>? destinationPins,
    MapPinOption? selectedPickup,
    MapPinOption? selectedDestination,
  }) {
    return MapPinsLoaded(
      query: query ?? this.query,
      pickupPins: pickupPins ?? this.pickupPins,
      destinationPins: destinationPins ?? this.destinationPins,
      selectedPickup: selectedPickup ?? this.selectedPickup,
      selectedDestination: selectedDestination ?? this.selectedDestination,
    );
  }
}

class MapPinsError extends MapPinsState {
  const MapPinsError(this.message);

  final String message;
}
