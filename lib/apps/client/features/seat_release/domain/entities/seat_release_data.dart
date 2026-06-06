class SeatReleaseData {
  const SeatReleaseData({
    required this.packageName,
    required this.packageType,
    required this.packageRoute,
    required this.startDate,
    required this.endDate,
    required this.packageStatus,
    required this.remainingDays,
    required this.releasedSeatsThisMonth,
    required this.successfullyRebookedSeats,
    required this.totalCompensationEarned,
    required this.reasons,
    required this.upcomingTrips,
    required this.pastReleases,
  });

  final String packageName;
  final String packageType;
  final String packageRoute;
  final String startDate;
  final String endDate;
  final String packageStatus;
  final int remainingDays;
  final int releasedSeatsThisMonth;
  final int successfullyRebookedSeats;
  final int totalCompensationEarned;
  final List<String> reasons;
  final List<UpcomingTrip> upcomingTrips;
  final List<SeatReleaseRecord> pastReleases;
}

class UpcomingTrip {
  const UpcomingTrip({
    required this.id,
    required this.date,
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.vehicle,
    required this.seatNumber,
    this.isReleased = false,
  });

  final String id;
  final String date;
  final String pickup;
  final String destination;
  final String departureTime;
  final String vehicle;
  final String seatNumber;
  final bool isReleased;
}

class SeatReleaseRecord {
  const SeatReleaseRecord({
    required this.releaseId,
    required this.releaseDate,
    required this.tripDate,
    required this.route,
    required this.seatNumber,
    required this.reason,
    required this.notes,
    required this.status,
    this.compensationType,
    this.compensationAmount,
    this.rewardDate,
  });

  final String releaseId;
  final String releaseDate;
  final String tripDate;
  final String route;
  final String seatNumber;
  final String reason;
  final String notes;
  final String status;
  final String? compensationType;
  final String? compensationAmount;
  final String? rewardDate;
}
