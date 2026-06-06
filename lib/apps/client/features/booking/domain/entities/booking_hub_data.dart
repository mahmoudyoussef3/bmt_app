class BookingHubData {
  const BookingHubData({
    required this.todayRoutes,
    required this.monthPlans,
    required this.activeTrips,
    required this.upcomingBookings,
    required this.reservedSeats,
  });

  final String todayRoutes;
  final String monthPlans;
  final String activeTrips;
  final String upcomingBookings;
  final String reservedSeats;
}
