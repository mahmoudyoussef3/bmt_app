import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/booking_option.dart';
import '../../domain/entities/daily_booking_data.dart';
import '../../domain/entities/vehicle_detail.dart';

sealed class BookingState {
  const BookingState();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingHubLoaded extends BookingState {
  const BookingHubLoaded(this.data);

  final BookingHubData data;
}

class DailyBookingLoaded extends BookingState {
  const DailyBookingLoaded(this.data);

  final DailyBookingData data;
}

class BookingRoutesLoaded extends BookingState {
  const BookingRoutesLoaded(this.routes);

  final List<RouteOptionData> routes;
}

class PopularRoutesLoaded extends BookingState {
  const PopularRoutesLoaded(this.routes);

  final List<PopularRouteListData> routes;
}

class MapPinsLoaded extends BookingState {
  const MapPinsLoaded({required this.pickup, required this.destination});

  final List<MapPinOption> pickup;
  final List<MapPinOption> destination;
}

class VehiclesLoaded extends BookingState {
  const VehiclesLoaded(this.vehicles);

  final List<VehicleDetailData> vehicles;
}

class VehicleDetailsLoaded extends BookingState {
  const VehicleDetailsLoaded(this.vehicle);

  final VehicleDetailData? vehicle;
}

class BookingError extends BookingState {
  const BookingError(this.message);

  final String message;
}
