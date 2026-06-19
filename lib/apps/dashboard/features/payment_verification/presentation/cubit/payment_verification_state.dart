import '../../domain/entities/booking_payment_verification.dart';

enum PaymentVerificationFilter {
  all('الكل'),
  pending('بانتظار'),
  reviewRequested('مراجعة'),
  approved('مقبولة'),
  rejected('مرفوضة');

  final String label;

  const PaymentVerificationFilter(this.label);
}

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
  final PaymentVerificationFilter filter;
  final String query;
  final bool isSaving;
  final String? message;
  final String? errorMessage;

  const PaymentVerificationLoaded({
    required this.items,
    required this.selectedId,
    this.receiptZoom = 1,
    this.filter = PaymentVerificationFilter.all,
    this.query = '',
    this.isSaving = false,
    this.message,
    this.errorMessage,
  });

  List<BookingPaymentVerification> get visibleItems {
    final normalizedQuery = query.trim().toLowerCase();
    return items.where((item) {
      final matchesFilter = switch (filter) {
        PaymentVerificationFilter.all => true,
        PaymentVerificationFilter.pending =>
          item.status == BookingVerificationStatus.pending,
        PaymentVerificationFilter.reviewRequested =>
          item.status == BookingVerificationStatus.reviewRequested,
        PaymentVerificationFilter.approved =>
          item.status == BookingVerificationStatus.approved,
        PaymentVerificationFilter.rejected =>
          item.status == BookingVerificationStatus.rejected,
      };
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      final searchable = [
        item.customer.name,
        item.customer.phone,
        item.bookingId,
        item.trip.route,
        item.trip.tripId,
        item.selectedSeat,
        item.referenceNumber,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  BookingPaymentVerification? get selectedItem {
    final visible = visibleItems;
    if (visible.isEmpty) return null;
    for (final item in visible) {
      if (item.id == selectedId) return item;
    }
    return visible.first;
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
    PaymentVerificationFilter? filter,
    String? query,
    bool? isSaving,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return PaymentVerificationLoaded(
      items: items ?? this.items,
      selectedId: selectedId ?? this.selectedId,
      receiptZoom: receiptZoom ?? this.receiptZoom,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      isSaving: isSaving ?? this.isSaving,
      message: clearMessage ? null : message ?? this.message,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
