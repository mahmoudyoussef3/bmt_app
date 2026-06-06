import '../models/home_data_model.dart';

class MockHomeDatasource {
  const MockHomeDatasource();

  Future<HomeDataModel> getHomeData() async {
    return const HomeDataModel(
      popularRoutes: [
        PopularRouteModel(
          pickup: 'Banha Center',
          destination: 'Smart Village',
          duration: '45 min',
          startingPrice: 'EGP 85',
        ),
        PopularRouteModel(
          pickup: 'Banha Station',
          destination: 'Nasr City',
          duration: '55 min',
          startingPrice: 'EGP 95',
        ),
        PopularRouteModel(
          pickup: 'Banha Downtown',
          destination: 'Mohandessin',
          duration: '1h 10m',
          startingPrice: 'EGP 120',
        ),
        PopularRouteModel(
          pickup: 'Smart Village',
          destination: 'Banha Center',
          duration: '48 min',
          startingPrice: 'EGP 85',
        ),
      ],
      nearbyTrips: [
        NearbyTripModel(
          pickup: 'Banha Station',
          destination: 'Smart Village',
          departureTime: '8:30 AM',
          seatsLeft: 12,
          isLive: true,
        ),
        NearbyTripModel(
          pickup: 'Banha Center',
          destination: 'Nasr City',
          departureTime: '9:00 AM',
          seatsLeft: 6,
          isLive: true,
        ),
        NearbyTripModel(
          pickup: 'Downtown Banha',
          destination: 'Mohandessin',
          departureTime: '9:15 AM',
          seatsLeft: 3,
          isLive: false,
        ),
      ],
      currentTrip: HomeCurrentTripModel(
        pickup: 'Banha Station',
        destination: 'Smart Village',
        schedule: 'Today, Jun 3 · Departs 8:40 AM',
        statusLabel: 'Driver assigned',
        driverLine: 'Pickup ETA 8:32 AM',
      ),
      packagePlans: [
        PackagePlanModel(
          title: 'Weekly Package',
          subtitle: '5 round trips · flexible seat',
          price: 'EGP 450',
          badge: 'Popular',
          iconKey: 'dateRange',
        ),
        PackagePlanModel(
          title: 'Bi-Weekly Package',
          subtitle: '10 round trips · priority boarding',
          price: 'EGP 820',
          badge: 'Save 8%',
          iconKey: 'calendarWeek',
        ),
        PackagePlanModel(
          title: 'Monthly Package',
          subtitle: 'Unlimited weekdays · best value',
          price: 'EGP 1,200',
          badge: 'Best value',
          iconKey: 'calendarMonth',
        ),
      ],
      pickupSuggestions: [
        'Banha Center',
        'Banha Station',
        'Banha Downtown',
        'Smart Village Gate',
      ],
      destinationSuggestions: [
        'Smart Village',
        'Nasr City',
        'Mohandessin',
        '6th of October',
      ],
      timeSuggestions: ['7:30 AM', '8:00 AM', '8:30 AM', '9:00 AM', '9:30 AM'],
    );
  }
}
