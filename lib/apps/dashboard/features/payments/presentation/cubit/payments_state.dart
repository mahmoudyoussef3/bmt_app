import '../../domain/entities/finance_payment.dart';

sealed class PaymentsState {
  const PaymentsState();
}

class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError(this.message);
}

class PaymentsLoaded extends PaymentsState {
  final List<FinancePayment> payments;
  final String selectedPaymentId;
  final double receiptZoom;
  final List<Map<String, dynamic>> availableTrips;
  final String? reassignError;

  const PaymentsLoaded({
    required this.payments,
    required this.selectedPaymentId,
    this.receiptZoom = 1,
    this.availableTrips = const [],
    this.reassignError,
  });

  FinancePayment? get selectedPayment {
    if (payments.isEmpty) return null;
    return payments.firstWhere(
      (payment) => payment.id == selectedPaymentId,
      orElse: () => payments.first,
    );
  }

  int get pendingCount {
    return payments
        .where((payment) => payment.status == PaymentReviewStatus.pendingReview)
        .length;
  }

  int get needsReviewCount {
    return payments
        .where((payment) => payment.status == PaymentReviewStatus.needsReview)
        .length;
  }

  PaymentsLoaded copyWith({
    List<FinancePayment>? payments,
    String? selectedPaymentId,
    double? receiptZoom,
    List<Map<String, dynamic>>? availableTrips,
    String? reassignError,
    bool clearReassignError = false,
  }) {
    return PaymentsLoaded(
      payments: payments ?? this.payments,
      selectedPaymentId: selectedPaymentId ?? this.selectedPaymentId,
      receiptZoom: receiptZoom ?? this.receiptZoom,
      availableTrips: availableTrips ?? this.availableTrips,
      reassignError: clearReassignError ? null : (reassignError ?? this.reassignError),
    );
  }
}
