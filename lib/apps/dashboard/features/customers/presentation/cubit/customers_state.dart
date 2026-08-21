import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';

/// How many customers one page of the directory holds.
///
/// Server-side paging, not a cap: reaching further is another request rather
/// than a truncation, so this module needs no `DashboardCapNotice` — the total
/// beside the table is the real total, whatever page is on screen.
const int customersPageSize = 25;

sealed class CustomersState {
  const CustomersState();
}

class CustomersLoadingState extends CustomersState {
  const CustomersLoadingState();
}

class CustomersErrorState extends CustomersState {
  final String message;

  const CustomersErrorState(this.message);
}

/// The loaded directory.
///
/// A failed *load* becomes [CustomersErrorState]; a failed *page turn* or
/// *filter change* keeps this state and surfaces [actionError]. Dropping to an
/// error screen after one refused request would discard the search and the
/// filters the operator built to get there, which is the more expensive loss.
class CustomersLoadedState extends CustomersState {
  final CustomersOverview overview;
  final CustomerDirectoryPage page;
  final CustomerFilters filters;

  /// Zero-based. The table's own pager is one-based and converts at the edge.
  final int pageIndex;

  /// True while a filter change or page turn is in flight. The page stays on
  /// screen and dims rather than being replaced by a spinner.
  final bool listLoading;

  /// The KPI strip failed while the list arrived. The counts are a summary of
  /// the same base the table shows, so losing them is worth a notice and not
  /// worth the page — see `DashboardPartialDataNotice`.
  final bool overviewFailed;

  /// One-shot feedback for a refused request. Does not survive the next
  /// emission, because a sticky message re-fires its snackbar on every rebuild.
  final String? actionError;

  const CustomersLoadedState({
    required this.overview,
    required this.page,
    this.filters = const CustomerFilters(),
    this.pageIndex = 0,
    this.listLoading = false,
    this.overviewFailed = false,
    this.actionError,
  });

  /// Total pages for the pager, never below one — an empty result is still
  /// "page 1 of 1" rather than "page 1 of 0".
  int get pageCount => (page.total / customersPageSize).ceil().clamp(1, 99999);

  bool get isEmpty => page.rows.isEmpty;

  /// Distinguishes "this office has no customers yet" from "nothing matched",
  /// which need different empty states: the first is a fact about the business,
  /// the second is a fact about the filters.
  bool get isFilteredEmpty => isEmpty && !filters.isEmpty;

  CustomersLoadedState copyWith({
    CustomersOverview? overview,
    CustomerDirectoryPage? page,
    CustomerFilters? filters,
    int? pageIndex,
    bool? listLoading,
    bool? overviewFailed,
    String? actionError,
    bool clearActionError = false,
  }) => CustomersLoadedState(
    overview: overview ?? this.overview,
    page: page ?? this.page,
    filters: filters ?? this.filters,
    pageIndex: pageIndex ?? this.pageIndex,
    listLoading: listLoading ?? this.listLoading,
    overviewFailed: overviewFailed ?? this.overviewFailed,
    actionError: clearActionError ? null : (actionError ?? this.actionError),
  );
}
