import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/office_invoice.dart';
import '../../domain/usecases/get_office_invoices_usecase.dart';

/// How many invoices are pulled in one read.
///
/// The RPC clamps `p_limit` to `[1, 200]`, and the cubit used to take the
/// default 50 with no pager over it — so an office that had been trading for
/// four years silently lost the first year of its own history. 200 is the most
/// the server will give in one call; the screen pages that window locally and
/// says so when it is full, which is honest in a way "50, silently" was not.
const int officeInvoiceWindow = 200;

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
    this.invoicesError,
    this.isLoadingInvoices = false,
    this.officeName = '',
  });

  final EntitlementContext entitlements;
  final List<OfficeInvoice> invoices;

  /// Set when the invoice read failed while the entitlement document loaded.
  ///
  /// The two halves are fetched independently now. A billing outage used to
  /// take the whole screen down — plan, limits and features with it — which is
  /// the one moment an owner most needs to read *why* their account is in the
  /// state it is in. The invoice panel carries this error and its own retry;
  /// everything above it stays true.
  final String? invoicesError;

  final bool isLoadingInvoices;

  /// Named on the upgrade request the office copies to send. Empty when the
  /// session has not resolved an office, which the screen simply omits.
  final String officeName;

  LicenseSummary get license => entitlements.license;

  /// The meters this office is actually held to.
  ///
  /// `isPublic && enforced`, the same rule [included] applies to features, and
  /// for the same reason: `max_branches` and `max_api_calls_per_month` are
  /// internal catalogue rows with no code behind them, and they were rendering
  /// as «0 / 0 فرع» — a meter that reads as broken rather than as absent.
  List<ResolvedFeature> get meters => entitlements.limits
      .where((f) => f.isPublic && f.enforced)
      .toList(growable: false);

  /// Meters with a real ceiling — the only ones a progress bar can describe.
  List<ResolvedFeature> get cappedMeters =>
      meters.where((f) => (f.limit ?? 0) > 0).toList(growable: false);

  /// Meters the plan does not cap at all. A bar drawn for one of these is a bar
  /// that can never move, which is what made the old panel unreadable: ten
  /// «بلا حدود» tracks and one real figure, all at the same weight.
  List<ResolvedFeature> get uncappedMeters =>
      meters.where((f) => f.isUnlimited).toList(growable: false);

  /// Meters set to zero: not a limit the office is near, but a capability the
  /// plan withholds entirely.
  List<ResolvedFeature> get closedMeters =>
      meters.where((f) => f.limit == 0).toList(growable: false);

  List<ResolvedFeature> get overLimitMeters =>
      cappedMeters.where((f) => f.isOverLimit).toList(growable: false);

  /// At or past 85% of the ceiling without having crossed it — the band where
  /// telling the owner still lets them act.
  List<ResolvedFeature> get nearLimitMeters => cappedMeters
      .where((f) => !f.isOverLimit && (f.used ?? 0) / f.limit! >= 0.85)
      .toList(growable: false);

  /// Grouped the way the office thinks about its own account: by category, and
  /// only the features it could actually have. A `declared` feature is left out
  /// entirely — offering an upgrade for something the code cannot deliver is
  /// the one thing this screen must never do.
  List<ResolvedFeature> included(String categoryKey) => entitlements
      .byCategory(categoryKey)
      .where((f) => f.isPublic && f.enforced && f.valueType != 'limit')
      .toList(growable: false);

  OfficeBillingLoaded copyWith({
    List<OfficeInvoice>? invoices,
    String? invoicesError,
    bool clearInvoicesError = false,
    bool? isLoadingInvoices,
  }) => OfficeBillingLoaded(
    entitlements: entitlements,
    invoices: invoices ?? this.invoices,
    invoicesError: clearInvoicesError
        ? null
        : (invoicesError ?? this.invoicesError),
    isLoadingInvoices: isLoadingInvoices ?? this.isLoadingInvoices,
    officeName: officeName,
  );
}

/// The office's own view of what it bought.
///
/// Reads the SAME resolved document the shell already holds, so this screen
/// cannot disagree with the nav beside it, and asking for it costs no second
/// entitlement call — only the invoice history is fetched.
class OfficeBillingCubit extends Cubit<OfficeBillingState> {
  OfficeBillingCubit(this._getInvoices, this._entitlements, this._session)
    : super(const OfficeBillingLoading());

  final GetOfficeInvoicesUseCase _getInvoices;
  final EntitlementService _entitlements;
  final DashboardSession _session;

  Future<void> load() async {
    emit(const OfficeBillingLoading());

    // The resolver silently returns nothing for a caller with no office, and so
    // does the invoice RPC — but it at least refuses by name. Said here once,
    // rather than letting both halves fail with a generic apology.
    if (_session.officeIdOrNull == null) {
      emit(const OfficeBillingError('حسابك غير مرتبط بمكتب.'));
      return;
    }

    // Refreshed rather than read from cache: this is the screen an owner opens
    // *because* they just paid or just upgraded, and a stale licence document
    // here would tell them the money never landed.
    await _entitlements.refresh();

    // `refresh()` never throws — a failed resolve leaves the permissive
    // `unknown` document, which is right for the shell (a network blip must not
    // hide half the console) and wrong here: rendering it would tell the owner
    // they have no licence and no features, which is a different and much more
    // alarming statement than "we could not read it".
    if (!_entitlements.isLoaded) {
      emit(const OfficeBillingError('تعذر تحميل بيانات الباقة.'));
      return;
    }

    final officeName = _session.context?.officeName ?? '';

    try {
      emit(
        OfficeBillingLoaded(
          entitlements: _entitlements.context,
          invoices: await _getInvoices(limit: officeInvoiceWindow),
          officeName: officeName,
        ),
      );
    } catch (error) {
      // The repository names what it can explain — no office membership reads
      // very differently to a dropped connection — so its sentence is shown as
      // written rather than flattened into one generic apology. It lands on the
      // invoice panel, not on the whole screen.
      emit(
        OfficeBillingLoaded(
          entitlements: _entitlements.context,
          invoicesError: _sentence(error),
          officeName: officeName,
        ),
      );
    }
  }

  /// Retries the invoice half alone, leaving the plan, the meters and the
  /// feature list on screen while it runs.
  Future<void> reloadInvoices() async {
    final current = state;
    if (current is! OfficeBillingLoaded) return;

    emit(current.copyWith(isLoadingInvoices: true, clearInvoicesError: true));
    try {
      final invoices = await _getInvoices(limit: officeInvoiceWindow);
      emit(
        current.copyWith(
          invoices: invoices,
          isLoadingInvoices: false,
          clearInvoicesError: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isLoadingInvoices: false,
          invoicesError: _sentence(error),
        ),
      );
    }
  }

  String _sentence(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
