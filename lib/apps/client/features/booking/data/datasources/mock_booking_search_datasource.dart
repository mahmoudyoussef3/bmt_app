import '../../domain/entities/booking_search_query.dart';
import '../models/booking_option_model.dart';

class MockBookingSearchDatasource {
  const MockBookingSearchDatasource();

  Future<List<RouteOptionModel>> getRoutes(BookingSearchQuery query) async {
    final pickup = query.pickup.isEmpty ? 'Banha Center' : query.pickup;
    final dest = query.destination.isEmpty
        ? 'Smart Village'
        : query.destination;

    return [
      RouteOptionModel(
        id: 'R1',
        pickup: pickup,
        destination: dest,
        duration: '45 min',
        availableSeats: 14,
        startingPrice: 'EGP 85',
        isFastest: true,
      ),
      RouteOptionModel(
        id: 'R2',
        pickup: pickup,
        destination: dest,
        duration: '52 min',
        availableSeats: 8,
        startingPrice: 'EGP 78',
      ),
      RouteOptionModel(
        id: 'R3',
        pickup: '$pickup · Express',
        destination: dest,
        duration: '38 min',
        availableSeats: 4,
        startingPrice: 'EGP 110',
      ),
    ];
  }

  Future<List<PopularRouteListModel>> getPopularRoutes() async {
    return _popularRoutes;
  }

  Future<List<AvailableTripModel>> getAvailableTrips(
    BookingSearchQuery query,
  ) async {
    return _availableTrips;
  }

  Future<List<MapPinOptionModel>> getPickupMapPins() async {
    return _pickupMapPins;
  }

  Future<List<MapPinOptionModel>> getDestinationMapPins() async {
    return _destinationMapPins;
  }
}

const _pickupMapPins = [
  MapPinOptionModel(
    label: 'Banha Center',
    subtitle: 'Main square pickup zone',
    x: 0.28,
    y: 0.62,
  ),
  MapPinOptionModel(
    label: 'Banha Station',
    subtitle: 'Rail station entrance',
    x: 0.42,
    y: 0.48,
  ),
];

const _destinationMapPins = [
  MapPinOptionModel(
    label: 'Smart Village',
    subtitle: 'Gate 3 corporate campus',
    x: 0.72,
    y: 0.32,
  ),
  MapPinOptionModel(
    label: 'Nasr City',
    subtitle: 'Abbas El Akkad stop',
    x: 0.68,
    y: 0.55,
  ),
];

const _popularRoutes = [
  PopularRouteListModel(
    routeName: 'Banha — Smart Village Express',
    dailyTrips: 24,
    averageDuration: '45 min',
    startingPrice: 'EGP 85',
    pickup: 'Banha Center',
    destination: 'Smart Village',
  ),
  PopularRouteListModel(
    routeName: 'Station — Nasr City Line',
    dailyTrips: 18,
    averageDuration: '55 min',
    startingPrice: 'EGP 95',
    pickup: 'Banha Station',
    destination: 'Nasr City',
  ),
  PopularRouteListModel(
    routeName: 'Downtown — Mohandessin',
    dailyTrips: 12,
    averageDuration: '1h 10m',
    startingPrice: 'EGP 120',
    pickup: 'Banha Downtown',
    destination: 'Mohandessin',
  ),
  PopularRouteListModel(
    routeName: 'Smart Village — Banha Return',
    dailyTrips: 20,
    averageDuration: '48 min',
    startingPrice: 'EGP 85',
    pickup: 'Smart Village Gate',
    destination: 'Banha Center',
  ),
  PopularRouteListModel(
    routeName: 'October Corridor',
    dailyTrips: 9,
    averageDuration: '1h 25m',
    startingPrice: 'EGP 135',
    pickup: 'Banha Station',
    destination: '6th of October',
  ),
];

const _availableTrips = [
  AvailableTripModel(
    vehicleId: 'MB-15-2847',
    vehicleType: 'Premium Coach',
    driverName: 'Ahmed Mohamed',
    estimatedArrival: '8:42 AM',
    routeDuration: '45 min',
    availableSeats: 6,
    startingPrice: 'EGP 85',
  ),
  AvailableTripModel(
    vehicleId: 'MB-22-1093',
    vehicleType: 'Standard Shuttle',
    driverName: 'Karim Ali',
    estimatedArrival: '8:55 AM',
    routeDuration: '52 min',
    availableSeats: 12,
    startingPrice: 'EGP 78',
  ),
  AvailableTripModel(
    vehicleId: 'MB-08-7721',
    vehicleType: 'Mini Bus',
    driverName: 'Hassan Ibrahim',
    estimatedArrival: '9:05 AM',
    routeDuration: '48 min',
    availableSeats: 3,
    startingPrice: 'EGP 92',
  ),
  AvailableTripModel(
    vehicleId: 'MB-31-4450',
    vehicleType: 'Executive Van',
    driverName: 'Omar Farouk',
    estimatedArrival: '9:12 AM',
    routeDuration: '38 min',
    availableSeats: 2,
    startingPrice: 'EGP 110',
  ),
];
