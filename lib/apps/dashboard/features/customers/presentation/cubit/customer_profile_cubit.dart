import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/customers_usecases.dart';
import 'customer_profile_state.dart';

/// Drives one customer's Customer 360 workspace.
///
/// ## Why the tabs are lazy
///
/// The header and نظرة عامة arrive in one round trip, because they are what the
/// operator opened the profile to read. The other four tabs are fetched the
/// first time they are shown and then kept: a customer with three years of
/// history costs four queries on open otherwise, three of which nobody looked
/// at.
///
/// ## Why a tab failure is not a page failure
///
/// Only the profile fetch can produce [CustomerProfileErrorState] — without it
/// there is no identity, no header and no summary. Every tab below owns its own
/// [CustomerTabStatus], so المدفوعات timing out leaves الرحلات on screen and
/// the header intact. The operator usually opened the profile to answer one
/// question, and the tab that answers it may not be the one that failed.
class CustomerProfileCubit extends Cubit<CustomerProfileState> {
  final GetCustomerProfileUseCase _getProfile;
  final GetCustomerTripsUseCase _getTrips;
  final GetCustomerSubscriptionsUseCase _getSubscriptions;
  final GetCustomerPaymentsUseCase _getPayments;
  final GetCustomerActivityUseCase _getActivity;

  /// Whose profile this is. Fixed for the cubit's life — the workspace is
  /// created per customer and disposed when the operator goes back to the list,
  /// so there is no "switch customer" path to leave a half-loaded tab behind.
  final String clientId;

  CustomerProfileCubit({
    required this.clientId,
    required GetCustomerProfileUseCase getProfile,
    required GetCustomerTripsUseCase getTrips,
    required GetCustomerSubscriptionsUseCase getSubscriptions,
    required GetCustomerPaymentsUseCase getPayments,
    required GetCustomerActivityUseCase getActivity,
  }) : _getProfile = getProfile,
       _getTrips = getTrips,
       _getSubscriptions = getSubscriptions,
       _getPayments = getPayments,
       _getActivity = getActivity,
       super(const CustomerProfileLoadingState());

  CustomerProfileLoadedState? get _loaded => state is CustomerProfileLoadedState
      ? state as CustomerProfileLoadedState
      : null;

  Future<void> load() async {
    emit(const CustomerProfileLoadingState());
    try {
      final profile = await _getProfile(clientId);
      if (isClosed) return;
      emit(CustomerProfileLoadedState(profile: profile));
    } catch (e) {
      if (isClosed) return;
      emit(CustomerProfileErrorState(_clean(e)));
    }
  }

  /// Re-reads the header and whichever tabs have already been loaded. A tab the
  /// operator never opened is not fetched by a refresh — refreshing is not the
  /// same request as opening.
  Future<void> refresh() async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(refreshing: true));
    try {
      final profile = await _getProfile(clientId);
      if (isClosed) return;
      emit((_loaded ?? current).copyWith(profile: profile, refreshing: false));
    } catch (_) {
      if (isClosed) return;
      // A failed refresh keeps the profile that is already on screen. It was
      // true a moment ago, and replacing it with an error would lose the tabs
      // beneath it as well.
      emit((_loaded ?? current).copyWith(refreshing: false));
    }

    final now = _loaded;
    if (now == null) return;
    if (now.tripsStatus.loaded) await loadTrips(force: true);
    if (now.subscriptionsStatus.loaded) await loadSubscriptions(force: true);
    if (now.paymentsStatus.loaded) await loadPayments(force: true);
    if (now.activityStatus.loaded) await loadActivity(force: true);
  }

  /// Switching tabs triggers that tab's first load and nothing else.
  Future<void> setTab(CustomerProfileTab tab) async {
    final current = _loaded;
    if (current == null || current.tab == tab) return;
    emit(current.copyWith(tab: tab));

    switch (tab) {
      case CustomerProfileTab.overview:
        break;
      case CustomerProfileTab.trips:
        await loadTrips();
      case CustomerProfileTab.subscriptions:
        await loadSubscriptions();
      case CustomerProfileTab.payments:
        await loadPayments();
      case CustomerProfileTab.activity:
        await loadActivity();
    }
  }

  /// Flips الرحلات between قادمة and سابقة, resetting to the first page and
  /// fetching the side that is now showing.
  Future<void> showPastTrips(bool past) async {
    final current = _loaded;
    if (current == null || current.showPastTrips == past) return;
    emit(current.copyWith(showPastTrips: past, tripsPageIndex: 0));
    await loadTrips(force: true);
  }

  /// [page] is a **zero-based index**, matching `OpsDataTable` and the rest of
  /// the console.
  Future<void> setTripsPage(int page) async {
    final current = _loaded;
    if (current == null) return;
    final index = page.clamp(0, current.tripsPageCount - 1);
    if (index == current.tripsPageIndex) return;
    emit(current.copyWith(tripsPageIndex: index));
    await loadTrips(force: true);
  }

  Future<void> setPaymentsPage(int page) async {
    final current = _loaded;
    if (current == null) return;
    final index = page.clamp(0, current.paymentsPageCount - 1);
    if (index == current.paymentsPageIndex) return;
    emit(current.copyWith(paymentsPageIndex: index));
    await loadPayments(force: true);
  }

  Future<void> loadTrips({bool force = false}) async {
    final current = _loaded;
    if (current == null) return;
    if (!force && current.tripsStatus.loaded) return;
    if (current.tripsStatus.loading) return;

    emit(
      current.copyWith(
        tripsStatus: current.tripsStatus.copyWith(
          loading: true,
          clearError: true,
        ),
      ),
    );
    try {
      final past = current.showPastTrips;
      final page = await _getTrips(
        clientId,
        upcoming: !past,
        limit: customerTripsPageSize,
        offset: current.tripsPageIndex * customerTripsPageSize,
      );
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(
        now.copyWith(
          upcomingTrips: past ? now.upcomingTrips : page,
          pastTrips: past ? page : now.pastTrips,
          tripsStatus: const CustomerTabStatus(loaded: true),
        ),
      );
    } catch (e) {
      _failTab(
        (now) => now.tripsStatus,
        (now, status) => now.copyWith(tripsStatus: status),
        _clean(e),
      );
    }
  }

  Future<void> loadSubscriptions({bool force = false}) async {
    final current = _loaded;
    if (current == null) return;
    if (!force && current.subscriptionsStatus.loaded) return;
    if (current.subscriptionsStatus.loading) return;

    emit(
      current.copyWith(
        subscriptionsStatus: current.subscriptionsStatus.copyWith(
          loading: true,
          clearError: true,
        ),
      ),
    );
    try {
      final subscriptions = await _getSubscriptions(clientId);
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(
        now.copyWith(
          subscriptions: subscriptions,
          subscriptionsStatus: const CustomerTabStatus(loaded: true),
        ),
      );
    } catch (e) {
      _failTab(
        (now) => now.subscriptionsStatus,
        (now, status) => now.copyWith(subscriptionsStatus: status),
        _clean(e),
      );
    }
  }

  Future<void> loadPayments({bool force = false}) async {
    final current = _loaded;
    if (current == null) return;
    if (!force && current.paymentsStatus.loaded) return;
    if (current.paymentsStatus.loading) return;

    emit(
      current.copyWith(
        paymentsStatus: current.paymentsStatus.copyWith(
          loading: true,
          clearError: true,
        ),
      ),
    );
    try {
      final payments = await _getPayments(
        clientId,
        limit: customerPaymentsPageSize,
        offset: current.paymentsPageIndex * customerPaymentsPageSize,
      );
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(
        now.copyWith(
          payments: payments,
          paymentsStatus: const CustomerTabStatus(loaded: true),
        ),
      );
    } catch (e) {
      _failTab(
        (now) => now.paymentsStatus,
        (now, status) => now.copyWith(paymentsStatus: status),
        _clean(e),
      );
    }
  }

  Future<void> loadActivity({bool force = false}) async {
    final current = _loaded;
    if (current == null) return;
    if (!force && current.activityStatus.loaded) return;
    if (current.activityStatus.loading) return;

    emit(
      current.copyWith(
        activityStatus: current.activityStatus.copyWith(
          loading: true,
          clearError: true,
        ),
      ),
    );
    try {
      final activity = await _getActivity(clientId);
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(
        now.copyWith(
          activity: activity,
          activityStatus: const CustomerTabStatus(loaded: true),
        ),
      );
    } catch (e) {
      _failTab(
        (now) => now.activityStatus,
        (now, status) => now.copyWith(activityStatus: status),
        _clean(e),
      );
    }
  }

  /// Records a tab's failure without disturbing the rest of the page. Keeps
  /// `loaded` as it was: a tab that had data and then failed a *refresh* still
  /// has the data, and should show it with the error beside it rather than
  /// throw it away.
  void _failTab(
    CustomerTabStatus Function(CustomerProfileLoadedState) read,
    CustomerProfileLoadedState Function(
      CustomerProfileLoadedState,
      CustomerTabStatus,
    )
    apply,
    String message,
  ) {
    if (isClosed) return;
    final now = _loaded;
    if (now == null) return;
    final status = read(now);
    emit(apply(now, status.copyWith(loading: false, error: message)));
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
