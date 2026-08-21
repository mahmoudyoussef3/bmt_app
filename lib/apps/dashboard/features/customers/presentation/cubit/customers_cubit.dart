import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui_state/dashboard_filter_memory.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';
import '../../domain/usecases/customers_usecases.dart';
import 'customers_state.dart';

/// Drives العملاء — the customer directory.
///
/// Three conventions run through every method:
///
///  1. **Nothing is filtered or sorted in Dart.** Every narrowing goes back to
///     `office_customer_directory`, because a page that has already been cut to
///     25 rows cannot be filtered without disagreeing with the total printed
///     beside it.
///
///  2. **A failed request never blanks a loaded screen.** Only the first load
///     produces [CustomersErrorState]; everything after reports through
///     `actionError`, because the operator's search and filters are worth more
///     than a tidy error page.
///
///  3. **Filters outlive the cubit.** The shell rebuilds a module from scratch
///     on every navigation, so an operator who narrows the list, opens a
///     customer and comes back would otherwise find the full list again. That
///     round trip is the most repeated motion in this module.
class CustomersCubit extends Cubit<CustomersState> {
  final GetCustomersOverviewUseCase _getOverview;
  final GetCustomerDirectoryUseCase _getDirectory;

  CustomersCubit({
    required GetCustomersOverviewUseCase getOverview,
    required GetCustomerDirectoryUseCase getDirectory,
  }) : _getOverview = getOverview,
       _getDirectory = getDirectory,
       super(const CustomersLoadingState());

  CustomersLoadedState? get _loaded =>
      state is CustomersLoadedState ? state as CustomersLoadedState : null;

  /// The request currently in flight, so a slow early response cannot overwrite
  /// a faster later one. Typing "أحمد" fires four requests as it debounces down;
  /// without this, whichever the server happens to answer last wins.
  int _requestSeq = 0;

  Future<void> load() async {
    emit(const CustomersLoadingState());

    final filters =
        DashboardFilterMemory.instance.read<CustomerFilters>(
          DashboardFilterIds.customers,
        ) ??
        const CustomerFilters();

    final seq = ++_requestSeq;

    // The list is the page; the KPI strip is a summary of it. If the strip
    // fails, the module is still usable, so the two are awaited separately and
    // only the list's failure is fatal.
    CustomersOverview overview = const CustomersOverview();
    var overviewFailed = false;

    try {
      final results = await Future.wait([
        _getDirectory(filters: filters, limit: customersPageSize, offset: 0),
        _getOverview().then<Object?>(
          (value) => value,
          onError: (_) {
            overviewFailed = true;
            return null;
          },
        ),
      ]);
      if (isClosed || seq != _requestSeq) return;

      final page = results[0] as CustomerDirectoryPage;
      final loadedOverview = results[1];
      if (loadedOverview is CustomersOverview) overview = loadedOverview;

      emit(
        CustomersLoadedState(
          overview: overview,
          page: page,
          filters: filters,
          overviewFailed: overviewFailed,
        ),
      );
    } catch (e) {
      if (isClosed || seq != _requestSeq) return;
      emit(CustomersErrorState(_clean(e)));
    }
  }

  /// Re-reads the page and the counts without tearing the screen down. Used by
  /// the header's refresh button and after returning from a customer profile.
  Future<void> refresh() async {
    final current = _loaded;
    if (current == null) return;
    await _fetch(
      current,
      current.filters,
      current.pageIndex,
      alsoOverview: true,
    );
  }

  /// Applies a search term. Already debounced by [DebouncedSearchField] at the
  /// widget, so this is not debounced again here — two debounces in series make
  /// the field feel broken.
  Future<void> search(String term) =>
      _applyFilters((filters) => filters.copyWith(search: term));

  Future<void> setSubscriptionFilter(CustomerSubscriptionFilter value) =>
      _applyFilters((filters) => filters.copyWith(subscription: value));

  Future<void> setUpcomingFilter(CustomerUpcomingFilter value) =>
      _applyFilters((filters) => filters.copyWith(upcoming: value));

  Future<void> setActivityFilter(CustomerActivityFilter value) =>
      _applyFilters((filters) => filters.copyWith(activity: value));

  Future<void> setStatusFilter(String? value) => _applyFilters(
    (filters) => value == null
        ? filters.copyWith(clearStatus: true)
        : filters.copyWith(status: value),
  );

  Future<void> setSort(CustomerSort value) =>
      _applyFilters((filters) => filters.copyWith(sort: value));

  /// Replaces the whole filter set at once — what a KPI tile does when it
  /// applies the predicate that produced its number.
  Future<void> applyFilters(CustomerFilters filters) =>
      _applyFilters((_) => filters);

  Future<void> clearFilters() async {
    final current = _loaded;
    if (current == null) return;
    DashboardFilterMemory.instance.forget(DashboardFilterIds.customers);
    await _fetch(current, const CustomerFilters(), 0, alsoOverview: false);
  }

  /// [page] is a **zero-based index**, which is what `OpsDataTable` reports and
  /// what every other paged module in the console uses. Passing a one-based
  /// number here renders "صفحة 2 من 1" on a single-page result.
  Future<void> setPage(int page) async {
    final current = _loaded;
    if (current == null) return;
    final index = page.clamp(0, current.pageCount - 1);
    if (index == current.pageIndex) return;
    await _fetch(current, current.filters, index, alsoOverview: false);
  }

  /// Any filter change resets to the first page. Staying on page 4 of a
  /// narrower result set lands the operator on an empty table and reads as
  /// "no results" for a filter that matched plenty.
  Future<void> _applyFilters(
    CustomerFilters Function(CustomerFilters) change,
  ) async {
    final current = _loaded;
    if (current == null) return;
    final filters = change(current.filters);
    DashboardFilterMemory.instance.write(DashboardFilterIds.customers, filters);
    await _fetch(current, filters, 0, alsoOverview: false);
  }

  Future<void> _fetch(
    CustomersLoadedState current,
    CustomerFilters filters,
    int pageIndex, {
    required bool alsoOverview,
  }) async {
    final seq = ++_requestSeq;

    // The new filters go on screen immediately so the controls reflect the
    // operator's choice while the rows behind them are still arriving.
    emit(
      current.copyWith(
        filters: filters,
        pageIndex: pageIndex,
        listLoading: true,
        clearActionError: true,
      ),
    );

    try {
      final page = await _getDirectory(
        filters: filters,
        limit: customersPageSize,
        offset: pageIndex * customersPageSize,
      );
      if (isClosed || seq != _requestSeq) return;

      var next = (_loaded ?? current).copyWith(
        page: page,
        filters: filters,
        pageIndex: pageIndex,
        listLoading: false,
      );

      if (alsoOverview) {
        try {
          final overview = await _getOverview();
          if (isClosed || seq != _requestSeq) return;
          next = next.copyWith(overview: overview, overviewFailed: false);
        } catch (_) {
          // The counts are a summary of a list that did arrive. Losing them is
          // a notice, not a failure of the page.
          next = next.copyWith(overviewFailed: true);
        }
      }

      emit(next);
    } catch (e) {
      if (isClosed || seq != _requestSeq) return;
      emit(
        (_loaded ?? current).copyWith(
          listLoading: false,
          actionError: _clean(e),
        ),
      );
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
