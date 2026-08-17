import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/office_invoice_model.dart';

abstract class OfficeBillingDatasource {
  /// The office's own invoice history, newest first. Paged at the RPC because
  /// an office that has been trading for years should not pay for its whole
  /// billing history to read this month's.
  Future<List<OfficeInvoiceModel>> getInvoices({int limit, int offset});
}

/// Invoices as the office sees them.
///
/// `office_invoices` is a SECURITY DEFINER RPC that resolves the caller's
/// office server-side and filters drafts out; there is no office id to pass and
/// none is accepted, so this cannot be pointed at another tenant.
class SupabaseOfficeBillingDatasource implements OfficeBillingDatasource {
  const SupabaseOfficeBillingDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OfficeInvoiceModel>> getInvoices({
    int limit = 50,
    int offset = 0,
  }) async {
    final raw = await _client.rpc(
      'office_invoices',
      params: {'p_limit': limit, 'p_offset': offset},
    );

    return [
      for (final row in (raw as List?) ?? const [])
        OfficeInvoiceModel.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }
}
