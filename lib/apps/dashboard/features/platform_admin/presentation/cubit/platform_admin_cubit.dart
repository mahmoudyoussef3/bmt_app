import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_filter.dart';
import '../../domain/usecases/platform_admin_usecases.dart';
import 'platform_admin_state.dart';

class PlatformAdminCubit extends Cubit<PlatformAdminState> {
  PlatformAdminCubit({
    required GetPlatformOfficesUseCase getOffices,
    required GetPlatformAnalyticsUseCase getAnalytics,
    required GetPlatformOfficeDetailsUseCase getOfficeDetails,
    required OnboardOfficeUseCase onboardOffice,
    required SetOfficeListingUseCase setListing,
    required SetOfficeStatusUseCase setStatus,
  }) : _getOffices = getOffices,
       _getAnalytics = getAnalytics,
       _getOfficeDetails = getOfficeDetails,
       _onboardOffice = onboardOffice,
       _setListing = setListing,
       _setStatus = setStatus,
       super(const PlatformAdminInitial());

  final GetPlatformOfficesUseCase _getOffices;
  final GetPlatformAnalyticsUseCase _getAnalytics;
  final GetPlatformOfficeDetailsUseCase _getOfficeDetails;
  final OnboardOfficeUseCase _onboardOffice;
  final SetOfficeListingUseCase _setListing;
  final SetOfficeStatusUseCase _setStatus;

  /// The search/filter facets and the open details panel live on the cubit, not
  /// only in the state, because every action reloads the list and re-emits
  /// `PlatformAdminLoaded`. Rebuilding that state from the office list alone
  /// would silently clear the operator's search and close whatever panel they
  /// were reading each time they pressed publish.
  PlatformOfficeFilter _filter = const PlatformOfficeFilter();
  PlatformOfficeSelection? _selection;

  /// Analytics is held beside the office list for the same reason the filter is
  /// — every action re-emits `PlatformAdminLoaded` — but it is also *separate*
  /// from the list on purpose: the two come from different RPCs, and losing the
  /// activity numbers must never lose the offices.
  PlatformAnalytics? _analytics;
  bool _isAnalyticsLoading = false;
  String? _analyticsError;
  int _windowDays = 30;

  Future<void> load() async {
    emit(const PlatformAdminLoading());
    try {
      final offices = await _getOffices();
      // The list is emitted before the analytics call is awaited, so the screen
      // is usable while the heavier aggregate query runs.
      _isAnalyticsLoading = true;
      emit(_loaded(offices));
      await _loadAnalytics();
    } catch (error) {
      emit(PlatformAdminError(_message(error)));
    }
  }

  /// Changes the analytics window (7 / 30 / 90 days) and refetches.
  ///
  /// Only the analytics call is repeated — the office list does not depend on
  /// the window, and refetching it would make a chart control flicker the whole
  /// screen.
  Future<void> setWindow(int days) async {
    if (days == _windowDays) return;
    _windowDays = days;
    final offices = _listOffices();
    if (offices == null) return;
    _isAnalyticsLoading = true;
    emit(_loaded(offices));
    await _loadAnalytics();
  }

  /// Fetches the activity numbers. Never throws: a failure here leaves the
  /// office list exactly as it was and records a message the header can show
  /// beside a retry, because "we could not measure the platform" is a smaller
  /// problem than "we could not list it" and must not be reported as the same
  /// thing.
  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _getAnalytics(windowDays: _windowDays);
      _analytics = analytics;
      _analyticsError = null;
    } catch (error) {
      _analyticsError = _message(error);
    }
    _isAnalyticsLoading = false;
    final offices = _listOffices();
    if (offices == null) return;
    emit(_loaded(offices));
  }

  Future<void> retryAnalytics() async {
    final offices = _listOffices();
    if (offices == null) return;
    _isAnalyticsLoading = true;
    _analyticsError = null;
    emit(_loaded(offices));
    await _loadAnalytics();
  }

  // ── Search and filtering ──────────────────────────────────────────────────
  // Purely local: `platform_list_offices()` returns every office the platform
  // has, and offices are onboarded one at a time by a human. See
  // [PlatformOfficeFilter] for why this does not go to the server.

  void search(String query) => _applyFilter(_filter.copyWith(query: query));

  void filterByStatus(String? status) => _applyFilter(
    status == null
        ? _filter.copyWith(clearStatus: true)
        : _filter.copyWith(status: status),
  );

  void filterByListingStatus(String? listingStatus) => _applyFilter(
    listingStatus == null
        ? _filter.copyWith(clearListingStatus: true)
        : _filter.copyWith(listingStatus: listingStatus),
  );

  void filterByActivity(ActivityLevel? activity) => _applyFilter(
    activity == null
        ? _filter.copyWith(clearActivity: true)
        : _filter.copyWith(activity: activity),
  );

  void sortBy(PlatformOfficeSort sort) =>
      _applyFilter(_filter.copyWith(sort: sort));

  void clearFilters() => _applyFilter(const PlatformOfficeFilter());

  void _applyFilter(PlatformOfficeFilter filter) {
    _filter = filter;
    final offices = _offices();
    if (offices == null) return;
    emit(_loaded(offices));
  }

  // ── Details ───────────────────────────────────────────────────────────────

  /// Opens the details panel for [officeId] and fetches it.
  ///
  /// The panel opens before the fetch resolves so the operator sees which office
  /// they picked immediately; a fetch that lands after they moved on is dropped
  /// rather than overwriting the office now on screen.
  Future<void> openDetails(String officeId) async {
    final offices = _offices();
    if (offices == null) return;

    _selection = PlatformOfficeSelection(officeId: officeId, isLoading: true);
    emit(_loaded(offices));

    try {
      final details = await _getOfficeDetails(officeId);
      if (_selection?.officeId != officeId) return;
      _selection = PlatformOfficeSelection(
        officeId: officeId,
        details: details,
      );
    } catch (error) {
      if (_selection?.officeId != officeId) return;
      _selection = PlatformOfficeSelection(
        officeId: officeId,
        error: _message(error),
      );
    }
    final current = _offices();
    if (current == null) return;
    emit(_loaded(current));
  }

  void closeDetails() {
    _selection = null;
    final offices = _offices();
    if (offices == null) return;
    emit(_loaded(offices));
  }

  Future<void> onboard(OfficeOnboardingRequest request) async {
    final offices = _offices();
    if (offices == null) return;

    emit(_loaded(offices, isSubmitting: true));
    try {
      final result = await _onboardOffice(request);
      // Reload before revealing: the new office has to be in the list the
      // operator returns to once they dismiss the credentials. A failed reload
      // must not swallow the reveal, so it degrades to the list we already had.
      List<PlatformOffice> refreshed;
      try {
        refreshed = await _getOffices();
      } catch (_) {
        refreshed = offices;
      }
      emit(PlatformAdminOnboarded(result, refreshed));
    } on OfficeOnboardingValidationException catch (e) {
      emit(
        PlatformAdminActionFailure(
          e.errors.values.first,
          offices,
          fieldErrors: e.errors,
        ),
      );
      emit(_loaded(offices, fieldErrors: e.errors));
    } catch (error) {
      emit(PlatformAdminActionFailure(_message(error), offices));
      emit(_loaded(offices));
    }
  }

  /// Dismisses the credentials panel and returns to the list. There is no way
  /// back: the password exists only in that state object.
  ///
  /// The analytics refresh happens here rather than at onboarding time because
  /// [_loadAnalytics] deliberately refuses to emit over the credentials panel —
  /// so this is the first moment the newly created office can be counted.
  Future<void> dismissOnboardingResult() async {
    final current = state;
    if (current is! PlatformAdminOnboarded) return;
    _isAnalyticsLoading = true;
    emit(_loaded(current.offices));
    await _loadAnalytics();
  }

  Future<void> setListing(String officeId, String listingStatus) =>
      _act(() => _setListing(officeId, listingStatus), switch (listingStatus) {
        'listed' => 'تم عرض المكتب في سوق العملاء',
        'unlisted' => 'تم سحب المكتب من سوق العملاء',
        _ => 'تم تحديث حالة العرض',
      });

  Future<void> setStatus(String officeId, String status) =>
      _act(() => _setStatus(officeId, status), switch (status) {
        'active' => 'تم تفعيل المكتب',
        'suspended' => 'تم إيقاف المكتب',
        'paused' => 'تم إيقاف المكتب مؤقتاً',
        _ => 'تم تحديث حالة المكتب',
      });

  /// Every small action follows the same arc: optimistic "busy", run, reload,
  /// announce. Written once so publish, withdraw and suspend cannot drift.
  Future<void> _act(
    Future<void> Function() action,
    String successMessage,
  ) async {
    final offices = _offices();
    if (offices == null) return;

    emit(_loaded(offices, isSubmitting: true));
    try {
      await action();
      final refreshed = await _getOffices();
      // Publishing from inside the details panel changes what that panel says —
      // the listing badge, and whether there is a marketplace preview at all. The
      // list refresh alone would leave it showing the pre-action office.
      await _refreshSelection();
      emit(PlatformAdminActionSuccess(successMessage, refreshed));
      emit(_loaded(refreshed));
      // Publishing or suspending changes the answers analytics gives — a newly
      // listed office with no upcoming trips becomes a marketplace dead end the
      // moment it is published — so the numbers are refetched rather than left
      // describing the platform as it was one action ago.
      await _loadAnalytics();
    } catch (error) {
      emit(PlatformAdminActionFailure(_message(error), offices));
      emit(_loaded(offices));
    }
  }

  /// Re-fetches the open panel, if one is open. A failure here is deliberately
  /// swallowed: the action it follows already succeeded, and reporting a stale
  /// panel as a failed publish would be a lie.
  Future<void> _refreshSelection() async {
    final officeId = _selection?.officeId;
    if (officeId == null) return;
    try {
      final details = await _getOfficeDetails(officeId);
      if (_selection?.officeId != officeId) return;
      _selection = PlatformOfficeSelection(
        officeId: officeId,
        details: details,
      );
    } catch (_) {
      // Keep whatever the panel was showing.
    }
  }

  /// The one place `PlatformAdminLoaded` is built, so the filter and the open
  /// panel cannot be dropped by a caller that forgot to pass them.
  PlatformAdminLoaded _loaded(
    List<PlatformOffice> offices, {
    bool isSubmitting = false,
    Map<String, String> fieldErrors = const {},
  }) => PlatformAdminLoaded(
    offices,
    isSubmitting: isSubmitting,
    fieldErrors: fieldErrors,
    filter: _filter,
    selection: _selection,
    analytics: _analytics,
    isAnalyticsLoading: _isAnalyticsLoading,
    analyticsError: _analyticsError,
  );

  /// The office list, but only when the screen is actually showing one.
  ///
  /// Stricter than [_offices] on purpose, and the difference matters: the
  /// credentials reveal also carries an office list, but it carries the only
  /// copy of a generated password that exists anywhere alongside it. Every
  /// analytics path emits `PlatformAdminLoaded`, so any of them reading
  /// [_offices] would silently replace that reveal with the list — losing the
  /// password to a background refresh the operator never asked for.
  List<PlatformOffice>? _listOffices() {
    final current = state;
    return current is PlatformAdminLoaded ? current.offices : null;
  }

  List<PlatformOffice>? _offices() {
    final current = state;
    return switch (current) {
      PlatformAdminLoaded() => current.offices,
      PlatformAdminOnboarded() => current.offices,
      PlatformAdminActionSuccess() => current.offices,
      PlatformAdminActionFailure() => current.offices,
      _ => null,
    };
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
