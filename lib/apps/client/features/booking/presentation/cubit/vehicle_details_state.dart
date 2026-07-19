import '../../domain/entities/vehicle_detail.dart';

sealed class VehicleDetailsState {
  const VehicleDetailsState();
}

class VehicleDetailsLoading extends VehicleDetailsState {
  const VehicleDetailsLoading();
}

class VehicleDetailsLoaded extends VehicleDetailsState {
  const VehicleDetailsLoaded(this.vehicle);

  final VehicleDetailData? vehicle;
}

class VehicleDetailsError extends VehicleDetailsState {
  const VehicleDetailsError(this.message);

  final String message;
}
