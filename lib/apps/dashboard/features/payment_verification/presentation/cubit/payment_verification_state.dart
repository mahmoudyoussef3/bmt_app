import '../../domain/entities/booking_payment_verification.dart';

sealed class PaymentVerificationState {
  const PaymentVerificationState();
}

class PaymentVerificationLoading extends PaymentVerificationState {
  const PaymentVerificationLoading();
}

class PaymentVerificationError extends PaymentVerificationState {
  final String message;

  const PaymentVerificationError(this.message);
}

class PaymentVerificationLoaded extends PaymentVerificationState {
  final List<BookingPaymentVerification> items;
  final String selectedId;
  final double receiptZoom;

  const PaymentVerificationLoaded({
    required this.items,
    required this.selectedId,
    this.receiptZoom = 1,
  });

  BookingPaymentVerification? get selectedItem {
    if (items.isEmpty) return null;
    return items.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => items.first,
    );
  }

  int get pendingCount {
    return items
        .where((item) => item.status == BookingVerificationStatus.pending)
        .length;
  }

  int get reviewCount {
    return items
        .where(
          (item) => item.status == BookingVerificationStatus.reviewRequested,
        )
        .length;
  }

  int get approvedCount {
    return items
        .where((item) => item.status == BookingVerificationStatus.approved)
        .length;
  }

  PaymentVerificationLoaded copyWith({
    List<BookingPaymentVerification>? items,
    String? selectedId,
    double? receiptZoom,
  }) {
    return PaymentVerificationLoaded(
      items: items ?? this.items,
      selectedId: selectedId ?? this.selectedId,
      receiptZoom: receiptZoom ?? this.receiptZoom,
    );
  }
}
