import '../../domain/entities/vehicle_detail.dart';

class VehicleDetailModel {
  const VehicleDetailModel({
    required this.id,
    required this.name,
    required this.model,
    required this.vehicleType,
    required this.imageLabels,
    required this.hasAirConditioning,
    required this.seatType,
    required this.hasRecliningSeats,
    required this.legRoomRating,
    required this.vehicleCondition,
    required this.driverName,
    required this.driverRating,
    required this.completedTrips,
    required this.yearsExperience,
    required this.price,
    required this.availableSeats,
    required this.estimatedArrival,
    required this.routeDuration,
    this.isRecommended = false,
    this.driverInitials = 'AM',
  });

  final String id;
  final String name;
  final String model;
  final String vehicleType;
  final List<String> imageLabels;
  final bool hasAirConditioning;
  final String seatType;
  final bool hasRecliningSeats;
  final double legRoomRating;
  final String vehicleCondition;
  final String driverName;
  final double driverRating;
  final int completedTrips;
  final int yearsExperience;
  final String price;
  final int availableSeats;
  final String estimatedArrival;
  final String routeDuration;
  final bool isRecommended;
  final String driverInitials;

  VehicleDetailData toEntity() {
    return VehicleDetailData(
      id: id,
      name: name,
      model: model,
      vehicleType: vehicleType,
      imageLabels: imageLabels,
      hasAirConditioning: hasAirConditioning,
      seatType: seatType,
      hasRecliningSeats: hasRecliningSeats,
      legRoomRating: legRoomRating,
      vehicleCondition: vehicleCondition,
      driverName: driverName,
      driverRating: driverRating,
      completedTrips: completedTrips,
      yearsExperience: yearsExperience,
      price: price,
      availableSeats: availableSeats,
      estimatedArrival: estimatedArrival,
      routeDuration: routeDuration,
      isRecommended: isRecommended,
      driverInitials: driverInitials,
    );
  }
}
