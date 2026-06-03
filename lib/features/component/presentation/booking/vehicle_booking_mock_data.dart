/// Full vehicle data for listing and details screens (UI only).
class VehicleDetailData {
  const VehicleDetailData({
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

  String get legRoomLabel {
    if (legRoomRating >= 4.5) return 'Excellent';
    if (legRoomRating >= 3.5) return 'Very good';
    if (legRoomRating >= 2.5) return 'Good';
    return 'Standard';
  }
}

const kVehicleCatalog = [
  VehicleDetailData(
    id: 'MB-15-2847',
    name: 'Mega Coach Elite',
    model: 'Mercedes-Benz Tourismo 2024',
    vehicleType: 'Premium Coach',
    imageLabels: ['Exterior', 'Cabin', 'Seats'],
    hasAirConditioning: true,
    seatType: 'Leather executive',
    hasRecliningSeats: true,
    legRoomRating: 4.8,
    vehicleCondition: 'Excellent',
    driverName: 'Ahmed Mohamed',
    driverInitials: 'AM',
    driverRating: 4.9,
    completedTrips: 2840,
    yearsExperience: 8,
    price: 'EGP 85',
    availableSeats: 6,
    estimatedArrival: '8:42 AM',
    routeDuration: '45 min',
    isRecommended: true,
  ),
  VehicleDetailData(
    id: 'MB-22-1093',
    name: 'City Shuttle Pro',
    model: 'Volvo 9700 2023',
    vehicleType: 'Standard Shuttle',
    imageLabels: ['Exterior', 'Interior'],
    hasAirConditioning: true,
    seatType: 'Fabric comfort',
    hasRecliningSeats: false,
    legRoomRating: 3.6,
    vehicleCondition: 'Good',
    driverName: 'Karim Ali',
    driverInitials: 'KA',
    driverRating: 4.7,
    completedTrips: 1920,
    yearsExperience: 5,
    price: 'EGP 78',
    availableSeats: 12,
    estimatedArrival: '8:55 AM',
    routeDuration: '52 min',
  ),
  VehicleDetailData(
    id: 'MB-08-7721',
    name: 'Compact Commuter',
    model: 'Toyota Coaster 2022',
    vehicleType: 'Mini Bus',
    imageLabels: ['Exterior', 'Cabin'],
    hasAirConditioning: true,
    seatType: 'Standard cushioned',
    hasRecliningSeats: false,
    legRoomRating: 3.2,
    vehicleCondition: 'Good',
    driverName: 'Hassan Ibrahim',
    driverInitials: 'HI',
    driverRating: 4.6,
    completedTrips: 1560,
    yearsExperience: 6,
    price: 'EGP 92',
    availableSeats: 3,
    estimatedArrival: '9:05 AM',
    routeDuration: '48 min',
  ),
  VehicleDetailData(
    id: 'MB-31-4450',
    name: 'Executive Van Plus',
    model: 'Mercedes Sprinter 2024',
    vehicleType: 'Executive Van',
    imageLabels: ['Exterior', 'Lounge', 'Seats', 'Amenities'],
    hasAirConditioning: true,
    seatType: 'Premium leather',
    hasRecliningSeats: true,
    legRoomRating: 4.5,
    vehicleCondition: 'Excellent',
    driverName: 'Omar Farouk',
    driverInitials: 'OF',
    driverRating: 4.95,
    completedTrips: 3210,
    yearsExperience: 10,
    price: 'EGP 110',
    availableSeats: 2,
    estimatedArrival: '9:12 AM',
    routeDuration: '38 min',
  ),
];

VehicleDetailData? vehicleById(String id) {
  for (final v in kVehicleCatalog) {
    if (v.id == id) return v;
  }
  return null;
}

List<VehicleDetailData> mockVehiclesForCompare() => kVehicleCatalog;

enum VehicleSortOption { recommended, priceLow, rating, seats }

List<VehicleDetailData> sortVehicles(
  List<VehicleDetailData> vehicles,
  VehicleSortOption option,
) {
  final list = List<VehicleDetailData>.from(vehicles);
  switch (option) {
    case VehicleSortOption.priceLow:
      list.sort((a, b) => _priceValue(a.price).compareTo(_priceValue(b.price)));
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
