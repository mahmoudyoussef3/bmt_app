import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import '../../domain/entities/office_invoice.dart';
import '../../domain/usecases/get_office_invoices_usecase.dart';

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
  OfficeBillingCubit(this._getInvoices, this._entitlements)
    : super(const OfficeBillingLoading());

  final GetOfficeInvoicesUseCase _getInvoices;
  final EntitlementService _entitlements;

  Future<void> load() async {
    emit(const OfficeBillingLoading());

    // Refreshed rather than read from cache: this is the screen an owner opens
    // *because* they just paid or just upgraded, and a stale licence document
    // here would tell them the money never landed.
    try {
      await _entitlements.refresh();
    } catch (_) {
      emit(const OfficeBillingError('تعذر تحميل بيانات الباقة.'));
      return;
    }

    try {
      emit(
        OfficeBillingLoaded(
          entitlements: _entitlements.context,
          invoices: await _getInvoices(),
        ),
      );
    } catch (error) {
      // The repository names what it can explain — no office membership reads
      // very differently to a dropped connection — so its sentence is shown as
      // written rather than flattened into one generic apology.
      emit(
        OfficeBillingError(error.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}
