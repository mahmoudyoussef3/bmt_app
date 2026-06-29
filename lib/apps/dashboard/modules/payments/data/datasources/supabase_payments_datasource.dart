import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/finance_payment.dart';
import 'booking_payments_store.dart';
import 'payments_datasource.dart';
import 'subscription_payments_store.dart';

class SupabasePaymentsDatasource implements PaymentsDatasource {
  const SupabasePaymentsDatasource(this._client);

  final SupabaseClient _client;

  BookingPaymentsStore get _bookings => BookingPaymentsStore(_client);
  SubscriptionPaymentsStore get _subscriptions =>
      SubscriptionPaymentsStore(_client);

  @override
  Future<List<FinancePayment>> fetchPayments() async {
    final results = await Future.wait([
      _bookings.fetch(),
      _subscriptions.fetch(),
    ]);
    return [...results[0], ...results[1]];
  }

  @override
  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  ) {
    if (_isSubscriptionId(paymentId)) {
      return _subscriptions.updateStatus(_rawId(paymentId), status);
    }
    return _bookings.updateStatus(paymentId, status);
  }

  @override
  Future<FinancePayment> addNote(String paymentId, String note) {
    if (_isSubscriptionId(paymentId)) {
      return _subscriptions.addNote(_rawId(paymentId), note);
    }
    return _bookings.addNote(paymentId, note);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableTrips() {
    return _bookings.fetchAvailableTrips();
  }

  @override
  Future<void> reassignBooking(String bookingId, String newTripId) {
    return _bookings.reassign(bookingId, newTripId);
  }

  bool _isSubscriptionId(String id) => id.startsWith('subscription:');

  String _rawId(String id) => id.substring('subscription:'.length);
}
