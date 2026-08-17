import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/office_invoice.dart';
import '../../domain/repositories/office_billing_repository.dart';
import '../datasources/supabase_office_billing_datasource.dart';

class OfficeBillingRepositoryImpl implements OfficeBillingRepository {
  const OfficeBillingRepositoryImpl(this._datasource);

  final OfficeBillingDatasource _datasource;

  @override
  Future<List<OfficeInvoice>> getInvoices({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _datasource.getInvoices(limit: limit, offset: offset);
    } on PostgrestException catch (e) {
      // The RPC refuses a caller with no office membership by name. That is the
      // one failure the screen can explain rather than apologise for, so it is
      // translated here instead of collapsing into the generic message.
      if (e.message.contains('not_an_office_user')) {
        throw Exception('حسابك غير مرتبط بمكتب.');
      }
      throw Exception('تعذر تحميل فواتير المكتب.');
    } catch (_) {
      throw Exception('تعذر تحميل فواتير المكتب.');
    }
  }
}
