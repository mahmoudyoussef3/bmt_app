import 'package:bmt_app/apps/client/features/home/domain/entities/home_active_package.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_booking.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_booking_status.dart';

export 'package:bmt_app/apps/client/features/home/domain/entities/home_active_package.dart';
export 'package:bmt_app/apps/client/features/home/domain/entities/home_booking.dart';
export 'package:bmt_app/apps/client/features/home/domain/entities/home_booking_status.dart';

class HomeData {
  const HomeData({
    required this.upcomingTrips,
    required this.pickupSuggestions,
    required this.destinationSuggestions,
    required this.timeSuggestions,
    this.bookings = const [],
    this.userName,
    this.activePackage,
  });

  final List<UpcomingTripData> upcomingTrips;

  /// Seats the rider already holds, soonest first. Empty for a signed-out or
  /// first-time rider.
  final List<HomeBookingData> bookings;

  final List<String> pickupSuggestions;
  final List<String> destinationSuggestions;
  final List<String> timeSuggestions;
  final String? userName;
  final HomeActivePackageData? activePackage;
}

/// A bookable departure on Home: the route it runs, when it leaves, what is
/// left on it and what it costs — everything needed to decide without
/// opening the trip.
class UpcomingTripData {
  const UpcomingTripData({
    required this.tripId,
    required this.routeId,
    required this.routeName,
    required this.pickup,
    required this.destination,
    required this.tripDate,
    required this.departureTime,
    required this.duration,
    required this.price,
    required this.seatsLeft,
    required this.isLive,
    this.officeName = '',
    this.bookedStatus,
    this.bookedSeats = 0,
  });

  final String tripId;
  final String routeId;
  final String routeName;
  final String pickup;
  final String destination;

  /// ISO `yyyy-MM-dd`; empty when the trip carries no date.
  final String tripDate;

  /// Raw `HH:mm:ss` from Supabase; empty when the trip has no time set.
  final String departureTime;

  final String duration;

  /// Preformatted fare (e.g. `EGP 100`); empty when no fare is published.
  final String price;

  final int seatsLeft;
  final bool isLive;

  /// The transport office running this departure — empty when unattributed.
  final String officeName;

  /// Where the rider's own booking on this departure stands, or `null` when
  /// they have not booked it. A booked trip stays in the feed and stays
  /// bookable — riders book the same departure again for a friend — but it
  /// must say so rather than pretend to be untouched.
  final HomeBookingStatus? bookedStatus;

  /// Seats the rider already holds on this departure.
  final int bookedSeats;

  bool get isBooked => bookedStatus != null;
  bool get isSoldOut => seatsLeft <= 0;
  bool get hasScarceSeats => seatsLeft > 0 && seatsLeft <= 5;
}
