import '../entities/vehicle_detail.dart';

class SortVehiclesUseCase {
  const SortVehiclesUseCase();

  List<VehicleDetailData> call(
    List<VehicleDetailData> vehicles,
    VehicleSortOption option,
  ) {
    final list = List<VehicleDetailData>.from(vehicles);
    switch (option) {
      case VehicleSortOption.priceLow:
        list.sort(
          (a, b) => _priceValue(a.price).compareTo(_priceValue(b.price)),
        );
      case VehicleSortOption.rating:
        // Best-reviewed captain + vehicle first. Unrated trips sort last rather
        // than first — an absent rating is not a perfect one.
        list.sort((a, b) => b.combinedRating.compareTo(a.combinedRating));
      case VehicleSortOption.seats:
        list.sort((a, b) => b.availableSeats.compareTo(a.availableSeats));
      case VehicleSortOption.recommended:
        // Recommended field removed. Sort by time (earliest departure first)
        list.sort((a, b) {
          final timeA =
              DateTime.tryParse('1970-01-01 ${a.departureTime}') ??
              DateTime(1970);
          final timeB =
              DateTime.tryParse('1970-01-01 ${b.departureTime}') ??
              DateTime(1970);
          return timeA.compareTo(timeB);
        });
    }
    return list;
  }

  int _priceValue(String price) {
    final digits = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
