import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';
import '../../domain/usecases/get_map_pins_usecase.dart';
import 'map_pins_state.dart';

/// Loads the pickup/destination map pins and tracks the stations the rider
/// selects on the map.
class MapPinsCubit extends Cubit<MapPinsState> {
  MapPinsCubit(this._getMapPins) : super(const MapPinsLoading());

  final GetMapPinsUseCase _getMapPins;
  BookingSearchQuery _query = const BookingSearchQuery();
  bool _inFlight = false;

  Future<void> load(BookingSearchQuery query) async {
    if (_inFlight) return;
    _inFlight = true;
    _query = query;
    emit(const MapPinsLoading());
    try {
      final pins = await _getMapPins();
      emit(
        MapPinsLoaded(
          query: _query,
          pickupPins: pins.pickup,
          destinationPins: pins.destination,
          selectedPickup: _findByLabel(pins.pickup, _query.pickup),
          selectedDestination: _findByLabel(
            pins.destination,
            _query.destination,
          ),
        ),
      );
    } catch (error) {
      emit(MapPinsError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }

  void reload() => load(_query);

  void selectPickup(MapPinOption pin) {
    final current = state;
    if (current is! MapPinsLoaded) return;
    emit(
      current.copyWith(
        selectedPickup: pin,
        query: current.query.copyWith(routeId: '', pickup: pin.label),
      ),
    );
  }

  void selectDestination(MapPinOption pin) {
    final current = state;
    if (current is! MapPinsLoaded) return;
    emit(
      current.copyWith(
        selectedDestination: pin,
        query: current.query.copyWith(routeId: '', destination: pin.label),
      ),
    );
  }

  MapPinOption? _findByLabel(List<MapPinOption> pins, String label) {
    if (label.isEmpty) return null;
    for (final pin in pins) {
      if (pin.label == label) return pin;
    }
    return null;
  }
}
