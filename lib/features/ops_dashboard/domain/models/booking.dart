class Booking {
  final String id;
  final String tripId;
  final String customerId;
  final BookingStatus status;
  final int seatNumber;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.tripId,
    required this.customerId,
    this.status = BookingStatus.pending,
    required this.seatNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum BookingStatus { pending, confirmed, cancelled, completed }
