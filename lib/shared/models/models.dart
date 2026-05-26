// Enums
enum UserRole { client, driver, admin }

enum BookingStatus { pending, confirmed, completed, cancelled, noShow }

enum SeatStatus { available, booked, selected }

enum TripStatus { scheduled, inProgress, completed, cancelled }

// Models
class User {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? email;
  final String? profileImage;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.profileImage,
  });
}

class Location {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class Seat {
  final String id;
  final int rowNumber;
  final int seatNumber;
  final SeatStatus status;

  const Seat({
    required this.id,
    required this.rowNumber,
    required this.seatNumber,
    required this.status,
  });

  Seat copyWith({SeatStatus? status}) {
    return Seat(
      id: id,
      rowNumber: rowNumber,
      seatNumber: seatNumber,
      status: status ?? this.status,
    );
  }
}

class Vehicle {
  final String id;
  final String number;
  final String type; // Minibus, Microbus, etc
  final int capacity;
  final int occupancy;
  final Driver driver;
  final List<Seat> seats;

  const Vehicle({
    required this.id,
    required this.number,
    required this.type,
    required this.capacity,
    required this.occupancy,
    required this.driver,
    required this.seats,
  });
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String license;
  final String profileImage;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.license,
    required this.profileImage,
  });
}

class Trip {
  final String id;
  final Vehicle vehicle;
  final Location pickupLocation;
  final Location dropoffLocation;
  final DateTime departureTime;
  final DateTime estimatedArrival;
  final int availableSeats;
  final double price;
  final TripStatus status;

  const Trip({
    required this.id,
    required this.vehicle,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.departureTime,
    required this.estimatedArrival,
    required this.availableSeats,
    required this.price,
    required this.status,
  });
}

class Booking {
  final String id;
  final User user;
  final Trip trip;
  final Seat seat;
  final BookingStatus status;
  final DateTime bookingDate;
  final double totalPrice;

  const Booking({
    required this.id,
    required this.user,
    required this.trip,
    required this.seat,
    required this.status,
    required this.bookingDate,
    required this.totalPrice,
  });
}

class MonthlySubscription {
  final String id;
  final User user;
  final Location pickupLocation;
  final Location dropoffLocation;
  final DateTime preferredArrival;
  final Seat preferredSeat;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double monthlyPrice;

  const MonthlySubscription({
    required this.id,
    required this.user,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.preferredArrival,
    required this.preferredSeat,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.monthlyPrice,
  });
}

class DashboardStats {
  final int totalVehicles;
  final int activeTrips;
  final int totalBookings;
  final int totalAvailableSeats;
  final double totalRevenue;

  const DashboardStats({
    required this.totalVehicles,
    required this.activeTrips,
    required this.totalBookings,
    required this.totalAvailableSeats,
    required this.totalRevenue,
  });
}
