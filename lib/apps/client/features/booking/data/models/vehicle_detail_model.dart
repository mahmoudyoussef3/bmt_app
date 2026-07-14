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
    required super.capacity,
    required super.availableSeats,
    required super.estimatedArrival,
    required super.routeDuration,
    required super.departureTime,
    super.driverInitials = 'AM',
    super.driverRating = 0,
    super.driverRatingCount = 0,
    super.vehicleRating = 0,
    super.vehicleRatingCount = 0,
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
      capacity: json['capacity'] as int? ?? 0,
      availableSeats: json['available_seats'] as int,
      estimatedArrival: json['estimated_arrival'] as String,
      routeDuration: json['route_duration'] as String,
      departureTime: json['departure_time'] as String,
      driverInitials: json['driver_initials'] as String? ?? 'AM',
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 0,
      driverRatingCount: (json['driver_rating_count'] as num?)?.toInt() ?? 0,
      vehicleRating: (json['vehicle_rating'] as num?)?.toDouble() ?? 0,
      vehicleRatingCount: (json['vehicle_rating_count'] as num?)?.toInt() ?? 0,
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
      'capacity': capacity,
      'available_seats': availableSeats,
      'estimated_arrival': estimatedArrival,
      'route_duration': routeDuration,
      'departure_time': departureTime,
      'driver_initials': driverInitials,
      'driver_rating': driverRating,
      'driver_rating_count': driverRatingCount,
      'vehicle_rating': vehicleRating,
      'vehicle_rating_count': vehicleRatingCount,
    };
  }
}
