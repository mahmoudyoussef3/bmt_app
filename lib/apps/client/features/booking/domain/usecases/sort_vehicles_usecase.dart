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
        list.sort((a, b) => b.driverRating.compareTo(a.driverRating));
      case VehicleSortOption.seats:
        list.sort((a, b) => b.availableSeats.compareTo(a.availableSeats));
      case VehicleSortOption.recommended:
        list.sort((a, b) {
          if (a.isRecommended != b.isRecommended) {
            return a.isRecommended ? -1 : 1;
          }
          return b.driverRating.compareTo(a.driverRating);
        });
    }
    return list;
  }

  int _priceValue(String price) {
    final digits = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
