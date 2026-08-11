import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import '../../domain/entities/office_invoice.dart';

sealed class OfficeBillingState {
  const OfficeBillingState();
}

class OfficeBillingLoading extends OfficeBillingState {
  const OfficeBillingLoading();
}

class OfficeBillingError extends OfficeBillingState {
  const OfficeBillingError(this.message);
  final String message;
}

class OfficeBillingLoaded extends OfficeBillingState {
  const OfficeBillingLoaded({
    required this.entitlements,
    this.invoices = const [],
  });

  final EntitlementContext entitlements;
  final List<OfficeInvoice> invoices;

  LicenseSummary get license => entitlements.license;

  /// Grouped the way the office thinks about its own account: by category, and
  /// only the features it could actually have. A `declared` feature is left out
  /// entirely — offering an upgrade for something the code cannot deliver is
  /// the one thing this screen must never do.
  List<ResolvedFeature> included(String categoryKey) => entitlements
      .byCategory(categoryKey)
      .where((f) => f.isPublic && f.enforced)
      .toList();
}

/// The office's own view of what it bought.
///
/// Reads the SAME resolved document the shell already holds, so this screen
/// cannot disagree with the nav beside it, and asking for it costs no second
/// entitlement call — only the invoice history is fetched.
class OfficeBillingCubit extends Cubit<OfficeBillingState> {
  OfficeBillingCubit(this._client, this._entitlements)
    : super(const OfficeBillingLoading());

  final SupabaseClient _client;
  final EntitlementService _entitlements;

  Future<void> load() async {
    emit(const OfficeBillingLoading());
    try {
      
      await _entitlements.refresh();

      final raw = await _client.rpc(
        'office_invoices',
        params: {'p_limit': 50, 'p_offset': 0},
      );

      emit(
        OfficeBillingLoaded(
          entitlements: _entitlements.context,
          invoices: [
            for (final e in (raw as List?) ?? const [])
              OfficeInvoice.fromJson(Map<String, dynamic>.from(e as Map)),
          ],
        ),
      );
    } on PostgrestException catch (e) {
      emit(OfficeBillingError(_message(e.message)));
    } catch (_) {
      emit(const OfficeBillingError('تعذر تحميل بيانات الباقة.'));
    }
  }

  String _message(String raw) {
    if (raw.contains('not_an_office_user')) {
      return 'حسابك غير مرتبط بمكتب.';
    }
    return 'تعذر تحميل بيانات الباقة.';
  }
}
