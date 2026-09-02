import '../../domain/entities/captain_request.dart';
import '../models/captain_request_sort.dart';

sealed class CaptainRequestsState {
  const CaptainRequestsState();
}

class CaptainRequestsLoading extends CaptainRequestsState {
  const CaptainRequestsLoading();
}

class CaptainRequestsError extends CaptainRequestsState {
  final String message;
  const CaptainRequestsError(this.message);
}

/// How many rows one page of the joining queue shows.
const int captainRequestsPageSize = 12;

/// How far back the queue reaches, counted from `created_at`.
///
/// A real narrowing rather than a placeholder behind the filter fold: an office
/// reviewing today's arrivals should not have to read past a year of decided
/// requests to find them.
enum CaptainRequestWindow {
  all('كل الفترات'),
  today('اليوم'),
  week('آخر ٧ أيام'),
  month('آخر ٣٠ يوماً');

  const CaptainRequestWindow(this.label);

  final String label;

  /// The earliest `created_at` this window admits, or null for [all].
  DateTime? startFrom(DateTime now) => switch (this) {
    CaptainRequestWindow.all => null,
    CaptainRequestWindow.today => DateTime(now.year, now.month, now.day),
    CaptainRequestWindow.week => now.subtract(const Duration(days: 7)),
    CaptainRequestWindow.month => now.subtract(const Duration(days: 30)),
  };
}

class CaptainRequestsLoaded extends CaptainRequestsState {
  final List<CaptainRequest> requests;

  /// Non-fatal action feedback (e.g. approve/reject failure) surfaced without
  /// blanking the list.
  final String? actionError;

  /// Free text matched against the driver's name, phone and note.
  final String searchQuery;

  /// The queue in view. Null is «كل الطلبات».
  final CaptainRequestStatus? filterStatus;

  /// How far back the queue reaches.
  final CaptainRequestWindow filterWindow;

  final CaptainRequestSort sort;
  final bool sortAscending;

  const CaptainRequestsLoaded({
    required this.requests,
    this.actionError,
    this.searchQuery = '',
    this.filterStatus = CaptainRequestStatus.pending,
    this.filterWindow = CaptainRequestWindow.all,
    this.sort = CaptainRequestSort.requestedAt,
    this.sortAscending = false,
  });

  List<CaptainRequest> get pending =>
      requests.where((r) => r.isPending).toList();
  int get pendingCount => pending.length;

  int get approvedCount =>
      requests.where((r) => r.status == CaptainRequestStatus.approved).length;

  int get rejectedCount =>
      requests.where((r) => r.status == CaptainRequestStatus.rejected).length;

  /// How long the office takes to answer, averaged over the requests that
  /// carry both timestamps.
  ///
  /// Null — rendered «—», never zero — when no decided request records a
  /// `reviewed_at`. "No data" and "answered instantly" are different claims and
  /// this console does not let one render as the other.
  Duration? get averageResponse {
    final decided = requests
        .where((r) => r.reviewedAt != null && !r.isPending)
        .toList();
    if (decided.isEmpty) return null;
    final total = decided.fold<int>(
      0,
      (sum, r) => sum + r.reviewedAt!.difference(r.createdAt).inMinutes,
    );
    return Duration(minutes: (total / decided.length).round());
  }

  /// The rows on screen: the queue's own filter, then the search, then the
  /// ordering — computed once here so the table, the card list, the results
  /// header and the pager can never disagree about what is in view.
  List<CaptainRequest> get visibleRequests {
    final term = searchQuery.trim().toLowerCase();
    final from = filterWindow.startFrom(DateTime.now());
    final filtered = requests.where((r) {
      if (filterStatus != null && r.status != filterStatus) return false;
      if (from != null && r.createdAt.isBefore(from)) return false;
      if (term.isEmpty) return true;
      return r.fullName.toLowerCase().contains(term) ||
          r.phone.contains(term) ||
          (r.note ?? '').toLowerCase().contains(term);
    }).toList();

    filtered.sort((a, b) {
      final cmp = switch (sort) {
        CaptainRequestSort.requestedAt => a.createdAt.compareTo(b.createdAt),
        CaptainRequestSort.name => a.fullName.compareTo(b.fullName),
        // A request with no decision yet sorts as the most recent one: it is
        // the row still waiting, which belongs at the top of a queue read
        // newest-first, not buried under decisions taken months ago.
        CaptainRequestSort.reviewedAt =>
          (a.reviewedAt ?? a.createdAt).compareTo(b.reviewedAt ?? b.createdAt),
      };
      return sortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  /// What the folded filter row is still doing. The queue tab is deliberately
  /// not counted — it is always visible above the fold, so counting it would
  /// mark the module "filtered" the moment it opens.
  int get activeFilterCount =>
      (searchQuery.trim().isEmpty ? 0 : 1) +
      (filterWindow == CaptainRequestWindow.all ? 0 : 1);

  CaptainRequestsLoaded copyWith({
    List<CaptainRequest>? requests,
    String? actionError,
    String? searchQuery,
    CaptainRequestStatus? filterStatus,
    bool clearStatusFilter = false,
    CaptainRequestWindow? filterWindow,
    CaptainRequestSort? sort,
    bool? sortAscending,
  }) {
    return CaptainRequestsLoaded(
      requests: requests ?? this.requests,
      actionError: actionError,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: clearStatusFilter
          ? null
          : (filterStatus ?? this.filterStatus),
      filterWindow: filterWindow ?? this.filterWindow,
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
