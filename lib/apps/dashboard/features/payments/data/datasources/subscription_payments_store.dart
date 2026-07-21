import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/finance_payment.dart';
import '../mappers/subscription_payment_mapper.dart';

class SubscriptionPaymentsStore {
  const SubscriptionPaymentsStore(this._client);

  final SupabaseClient _client;

  static const query = '''
    id, customer_name, customer_phone, status, created_at, total_price,
    payment_method, payment_reference, payment_receipt_url,
    payment_review_status, payment_notes, package_name, route_name
  ''';

  Future<List<FinancePayment>> fetch() async {
    final rows = await _client
        .from('subscriptions')
        .select(query)
        .order('created_at', ascending: false);
    return rows.map(mapSubscriptionPayment).toList();
  }

  Future<FinancePayment> updateStatus(
    String id,
    PaymentReviewStatus status,
  ) async {
    if (status == PaymentReviewStatus.accepted) {
      await _client.rpc(
        'office_confirm_subscription_payment',
        params: {'p_subscription_id': id},
      );
    } else {
      await _client
          .from('subscriptions')
          .update({
            'payment_review_status': subscriptionReviewStatusToDb(status),
            if (status == PaymentReviewStatus.rejected) 'status': 'cancelled',
          })
          .eq('id', id);
    }
    return _fetchOne(id);
  }

  Future<FinancePayment> addNote(String id, String note) async {
    final current = await _client
        .from('subscriptions')
        .select('payment_notes')
        .eq('id', id)
        .single();
    final notes = (current['payment_notes'] as List?)?.cast<String>() ?? [];
    await _client
        .from('subscriptions')
        .update({
          'payment_notes': [note, ...notes],
        })
        .eq('id', id);
    return _fetchOne(id);
  }

  Future<FinancePayment> _fetchOne(String id) async {
    final row = await _client
        .from('subscriptions')
        .select(query)
        .eq('id', id)
        .single();
    return mapSubscriptionPayment(row);
  }
}
