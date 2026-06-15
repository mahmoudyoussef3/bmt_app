import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/finance_entities.dart';
import 'finance_datasource.dart';
import 'mock_finance_datasource.dart'; // Temporarily use mock for unimplemented parts

class SupabaseFinanceDatasource implements FinanceDatasource {
  final SupabaseClient _client;
  final MockFinanceDatasource _mockDatasource; // Fallback for Phase 7 or unimplemented parts

  SupabaseFinanceDatasource(this._client) : _mockDatasource = MockFinanceDatasource();

  @override
  Future<List<PaymentRecord>> getPayments() async {
    // Ideally query operation_bookings
    return _mockDatasource.getPayments();
  }

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async {
    return _mockDatasource.getReceiptReviews();
  }

  @override
  Future<List<RefundRequest>> getRefundRequests() async {
    final response = await _client.from('refund_requests').select('''
      *,
      client:clients(full_name)
    ''').order('created_at', ascending: false);

    return response.map((json) {
      final client = json['client'] as Map<String, dynamic>? ?? {};
      final clientName = client['full_name']?.toString() ?? 'عميل غير معروف';

      RefundStatus mappedStatus = RefundStatus.pending;
      final statusStr = json['status']?.toString();
      if (statusStr == 'approved') mappedStatus = RefundStatus.approved;
      if (statusStr == 'rejected') mappedStatus = RefundStatus.rejected;

      return RefundRequest(
        id: json['id'],
        transactionId: json['booking_id'] ?? '',
        clientName: clientName,
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        status: mappedStatus,
        reason: json['reason'] ?? '',
        history: [], // Could map timeline if needed
      );
    }).toList();
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    return _mockDatasource.getSubscriptions();
  }

  @override
  Future<RevenueMetrics> getRevenueMetrics() async {
    return _mockDatasource.getRevenueMetrics();
  }

  @override
  Future<void> reviewReceipt(String id, ReceiptReviewStatus action, {String? notes}) async {
    _mockDatasource.reviewReceipt(id, action, notes: notes);
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    final dbStatus = action == RefundStatus.approved ? 'approved' : 'rejected';
    await _client.from('refund_requests').update({
      'status': dbStatus,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> cancelSubscription(String id) async {
    _mockDatasource.cancelSubscription(id);
  }
}
