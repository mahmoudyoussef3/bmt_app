import '../../domain/entities/vehicle.dart';

class VehicleFilters {
  final String search;
  final VehicleStatus? status;

  const VehicleFilters({this.search = '', this.status});

  VehicleFilters copyWith({
    String? search,
    VehicleStatus? status,
    bool clearStatus = false,
  }) {
    return VehicleFilters(
      search: search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}
