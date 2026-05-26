import 'package:bmt_app/shared/models/models.dart';

class MockData {
  // Locations
  static final locations = [
    Location(
      id: 'loc1',
      name: 'Banha Station',
      address: 'Banha, Qalyubia',
      latitude: 30.4658,
      longitude: 31.1853,
    ),
    Location(
      id: 'loc2',
      name: 'Banha Center',
      address: 'Downtown Banha',
      latitude: 30.4690,
      longitude: 31.1900,
    ),
    Location(
      id: 'loc3',
      name: 'Smart Village',
      address: 'Giza, Cairo',
      latitude: 30.0069,
      longitude: 31.1874,
    ),
    Location(
      id: 'loc4',
      name: 'October City',
      address: 'Giza, Cairo',
      latitude: 30.0444,
      longitude: 31.1667,
    ),
    Location(
      id: 'loc5',
      name: 'Nasr City',
      address: 'Cairo',
      latitude: 30.0800,
      longitude: 31.3567,
    ),
    Location(
      id: 'loc6',
      name: 'Sheraton',
      address: 'Cairo',
      latitude: 30.0450,
      longitude: 31.2356,
    ),
    Location(
      id: 'loc7',
      name: 'Mohandessin',
      address: 'Giza, Cairo',
      latitude: 30.0456,
      longitude: 31.1956,
    ),
    Location(
      id: 'loc8',
      name: 'Maadi',
      address: 'Cairo',
      latitude: 29.9844,
      longitude: 31.2456,
    ),
    Location(
      id: 'loc9',
      name: 'Helwan',
      address: 'Cairo',
      latitude: 29.8589,
      longitude: 31.3172,
    ),
  ];

  // Drivers
  static final drivers = [
    Driver(
      id: 'drv1',
      name: 'Ahmed Hassan',
      phone: '01012345678',
      license: 'LIC-001',
      profileImage: '👨‍✈️',
    ),
    Driver(
      id: 'drv2',
      name: 'Mohamed Ali',
      phone: '01123456789',
      license: 'LIC-002',
      profileImage: '👨‍✈️',
    ),
    Driver(
      id: 'drv3',
      name: 'Ibrahim Khalil',
      phone: '01234567890',
      license: 'LIC-003',
      profileImage: '👨‍✈️',
    ),
    Driver(
      id: 'drv4',
      name: 'Karim Nassar',
      phone: '01001234567',
      license: 'LIC-004',
      profileImage: '👨‍✈️',
    ),
  ];

  // Create seats for a vehicle (6 seats, 2 rows)
  static List<Seat> generateSeats({List<int>? bookedSeats}) {
    bookedSeats ??= [];
    List<Seat> seats = [];
    int seatIndex = 1;
    for (int row = 1; row <= 3; row++) {
      for (int seat = 1; seat <= 2; seat++) {
        final status = bookedSeats.contains(seatIndex)
            ? SeatStatus.booked
            : SeatStatus.available;
        seats.add(
          Seat(
            id: 'seat-$seatIndex',
            rowNumber: row,
            seatNumber: seat,
            status: status,
          ),
        );
        seatIndex++;
      }
    }
    return seats;
  }

  // Vehicles
  static final vehicles = [
    Vehicle(
      id: 'veh1',
      number: 'MEG-001',
      type: 'Minibus',
      capacity: 6,
      occupancy: 4,
      driver: drivers[0],
      seats: generateSeats(bookedSeats: [1, 2, 3]),
    ),
    Vehicle(
      id: 'veh2',
      number: 'MEG-002',
      type: 'Minibus',
      capacity: 6,
      occupancy: 3,
      driver: drivers[1],
      seats: generateSeats(bookedSeats: [2, 5]),
    ),
    Vehicle(
      id: 'veh3',
      number: 'MEG-003',
      type: 'Microbus',
      capacity: 6,
      occupancy: 2,
      driver: drivers[2],
      seats: generateSeats(bookedSeats: [1, 4]),
    ),
    Vehicle(
      id: 'veh4',
      number: 'MEG-004',
      type: 'Minibus',
      capacity: 6,
      occupancy: 5,
      driver: drivers[3],
      seats: generateSeats(bookedSeats: [1, 2, 3, 4, 5]),
    ),
    Vehicle(
      id: 'veh5',
      number: 'MEG-005',
      type: 'Microbus',
      capacity: 6,
      occupancy: 1,
      driver: drivers[0],
      seats: generateSeats(bookedSeats: [3]),
    ),
    Vehicle(
      id: 'veh6',
      number: 'MEG-006',
      type: 'Minibus',
      capacity: 6,
      occupancy: 4,
      driver: drivers[1],
      seats: generateSeats(bookedSeats: [1, 2, 4, 6]),
    ),
    Vehicle(
      id: 'veh7',
      number: 'MEG-007',
      type: 'Microbus',
      capacity: 6,
      occupancy: 0,
      driver: drivers[2],
      seats: generateSeats(bookedSeats: []),
    ),
    Vehicle(
      id: 'veh8',
      number: 'MEG-008',
      type: 'Minibus',
      capacity: 6,
      occupancy: 6,
      driver: drivers[3],
      seats: generateSeats(bookedSeats: [1, 2, 3, 4, 5, 6]),
    ),
  ];

  // Trips
  static List<Trip> getUpcomingTrips() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return [
      Trip(
        id: 'trip1',
        vehicle: vehicles[0],
        pickupLocation: locations[0],
        dropoffLocation: locations[2],
        departureTime: tomorrow.copyWith(hour: 6, minute: 30),
        estimatedArrival: tomorrow.copyWith(hour: 8, minute: 45),
        availableSeats: 3,
        price: 50.0,
        status: TripStatus.scheduled,
      ),
      Trip(
        id: 'trip2',
        vehicle: vehicles[1],
        pickupLocation: locations[1],
        dropoffLocation: locations[4],
        departureTime: tomorrow.copyWith(hour: 7, minute: 0),
        estimatedArrival: tomorrow.copyWith(hour: 9, minute: 15),
        availableSeats: 3,
        price: 60.0,
        status: TripStatus.scheduled,
      ),
      Trip(
        id: 'trip3',
        vehicle: vehicles[2],
        pickupLocation: locations[0],
        dropoffLocation: locations[5],
        departureTime: tomorrow.copyWith(hour: 6, minute: 45),
        estimatedArrival: tomorrow.copyWith(hour: 9, minute: 0),
        availableSeats: 4,
        price: 70.0,
        status: TripStatus.scheduled,
      ),
      Trip(
        id: 'trip4',
        vehicle: vehicles[3],
        pickupLocation: locations[2],
        dropoffLocation: locations[6],
        departureTime: tomorrow.copyWith(hour: 16, minute: 30),
        estimatedArrival: tomorrow.copyWith(hour: 18, minute: 0),
        availableSeats: 1,
        price: 55.0,
        status: TripStatus.scheduled,
      ),
      Trip(
        id: 'trip5',
        vehicle: vehicles[4],
        pickupLocation: locations[3],
        dropoffLocation: locations[7],
        departureTime: tomorrow.copyWith(hour: 17, minute: 0),
        estimatedArrival: tomorrow.copyWith(hour: 18, minute: 30),
        availableSeats: 5,
        price: 65.0,
        status: TripStatus.scheduled,
      ),
    ];
  }

  // Users
  static final currentUser = User(
    id: 'user1',
    name: 'Mahmoud Ahmed',
    phone: '01098765432',
    role: UserRole.client,
    email: 'mahmoud@example.com',
  );

  static final driverUser = User(
    id: 'driver1',
    name: 'Ahmed Hassan',
    phone: '01012345678',
    role: UserRole.driver,
  );

  static final adminUser = User(
    id: 'admin1',
    name: 'Admin User',
    phone: '01111111111',
    role: UserRole.admin,
  );

  // Bookings
  static List<Booking> getUserBookings(String userId) {
    final now = DateTime.now();
    return [
      Booking(
        id: 'book1',
        user: currentUser,
        trip: getUpcomingTrips()[0],
        seat: vehicles[0].seats[0],
        status: BookingStatus.confirmed,
        bookingDate: now.subtract(const Duration(days: 2)),
        totalPrice: 50.0,
      ),
      Booking(
        id: 'book2',
        user: currentUser,
        trip: Trip(
          id: 'past_trip1',
          vehicle: vehicles[1],
          pickupLocation: locations[0],
          dropoffLocation: locations[3],
          departureTime: now.subtract(const Duration(days: 1, hours: 2)),
          estimatedArrival: now.subtract(const Duration(days: 1)),
          availableSeats: 0,
          price: 50.0,
          status: TripStatus.completed,
        ),
        seat: vehicles[1].seats[1],
        status: BookingStatus.completed,
        bookingDate: now.subtract(const Duration(days: 3)),
        totalPrice: 50.0,
      ),
    ];
  }

  // Monthly Subscriptions
  static final monthlySubscription = MonthlySubscription(
    id: 'sub1',
    user: currentUser,
    pickupLocation: locations[0],
    dropoffLocation: locations[2],
    preferredArrival: DateTime.now().copyWith(hour: 8, minute: 30),
    preferredSeat: vehicles[0].seats[0],
    startDate: DateTime.now(),
    isActive: true,
    monthlyPrice: 1000.0,
  );

  // Dashboard Stats
  static final dashboardStats = DashboardStats(
    totalVehicles: vehicles.length,
    activeTrips: 8,
    totalBookings: 47,
    totalAvailableSeats: 12,
    totalRevenue: 5670.0,
  );
}
