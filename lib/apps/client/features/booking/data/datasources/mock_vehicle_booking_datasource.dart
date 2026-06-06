import '../models/vehicle_detail_model.dart';

class MockVehicleBookingDatasource {
  const MockVehicleBookingDatasource();

  Future<List<VehicleDetailModel>> getVehicles() async {
    return _vehicleCatalog;
  }

  Future<VehicleDetailModel?> getVehicleById(String id) async {
    for (final vehicle in _vehicleCatalog) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }
}

const _vehicleCatalog = [
  VehicleDetailModel(
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
  VehicleDetailModel(
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
  VehicleDetailModel(
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
  VehicleDetailModel(
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
