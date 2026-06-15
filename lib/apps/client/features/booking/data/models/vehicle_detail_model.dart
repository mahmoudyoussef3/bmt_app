import '../../domain/entities/vehicle_detail.dart';

class VehicleDetailModel extends VehicleDetailData {
  const VehicleDetailModel({
    required super.id,
    required super.name,
    required super.model,
    required super.vehicleType,
    required super.imageLabels,
    required super.hasAirConditioning,
    required super.seatType,
    required super.driverName,
    required super.price,
    required super.availableSeats,
    required super.estimatedArrival,
    required super.routeDuration,
    required super.departureTime,
    super.driverInitials = 'AM',
  });

  factory VehicleDetailModel.fromJson(Map<String, dynamic> json) {
    return VehicleDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String,
      vehicleType: json['vehicle_type'] as String,
      imageLabels: List<String>.from(json['image_labels'] as List? ?? []),
      hasAirConditioning: json['has_air_conditioning'] as bool? ?? false,
      seatType: json['seat_type'] as String,
      driverName: json['driver_name'] as String,
      price: json['price'] as String,
      availableSeats: json['available_seats'] as int,
      estimatedArrival: json['estimated_arrival'] as String,
      routeDuration: json['route_duration'] as String,
      departureTime: json['departure_time'] as String,
      driverInitials: json['driver_initials'] as String? ?? 'AM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'vehicle_type': vehicleType,
      'image_labels': imageLabels,
      'has_air_conditioning': hasAirConditioning,
      'seat_type': seatType,
      'driver_name': driverName,
      'price': price,
      'available_seats': availableSeats,
      'estimated_arrival': estimatedArrival,
      'route_duration': routeDuration,
      'departure_time': departureTime,
      'driver_initials': driverInitials,
    };
  }
}
