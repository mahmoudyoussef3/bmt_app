class PaymentTransaction {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.status = PaymentStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum PaymentStatus { pending, completed, failed, refunded }
