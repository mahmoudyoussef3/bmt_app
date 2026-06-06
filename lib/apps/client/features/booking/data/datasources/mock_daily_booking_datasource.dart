import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/daily_booking_data.dart';

class MockDailyBookingDatasource {
  const MockDailyBookingDatasource();

  Future<BookingHubData> getBookingHubData() async {
    return const BookingHubData(
      todayRoutes: '3 routes',
      monthPlans: '2 plans',
      activeTrips: '3',
      upcomingBookings: '9',
      reservedSeats: '27',
    );
  }

  Future<DailyBookingData> getDailyBookingData() async {
    return const DailyBookingData(
      pickupPoints: [
        'Banha Station',
        'Banha Center',
        'Banha Downtown',
        'Al-Sadat St',
      ],
      destinations: [
        'Smart Village',
        'Nasr City',
        'Mohandessin',
        'Maadi',
        'Sheraton',
        'October',
        'Metro Station',
      ],
      arrivalTimes: ['8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM'],
      vehicles: [
        DailyBookingVehicle(
          id: 'MT-2847',
          driver: 'Ahmed Mohamed',
          time: '8:40 AM',
          seatsLeft: 4,
          occupancy: 0.75,
        ),
        DailyBookingVehicle(
          id: 'MT-2848',
          driver: 'Karim Hassan',
          time: '8:50 AM',
          seatsLeft: 2,
          occupancy: 0.9,
        ),
        DailyBookingVehicle(
          id: 'MT-2849',
          driver: 'Mostafa Ali',
          time: '9:05 AM',
          seatsLeft: 6,
          occupancy: 0.5,
        ),
      ],
    );
  }
}
