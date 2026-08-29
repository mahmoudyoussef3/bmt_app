/// The narrowings and orderings محفظة العملاء' three tabs are worked through.
///
/// One value object per tab, and every one of them is *derived* state rather
/// than stored twice: the queue strip's selection, the KPI tiles' highlight and
/// the rows on screen all read the same object, so a tile can never disagree
/// with the list it opens.
///
/// The activity tab's *predicates* are not here — they live in
/// [WalletLedgerFilters] and are evaluated server-side, because the ledger is
/// paged and a client-side predicate over a page would filter the page rather
/// than the ledger. Its ordering is here, since it reorders only what arrived.
library;

import 'package:bmt_app/core/search/place_search_text.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';

/// Which slice of the customer directory is on screen.
///
/// Applied to the rows the directory RPC returned, not to the whole customer
/// base — the search term is what narrows server-side. Every count that names
/// one of these scopes is therefore counted from the same rows it filters.
enum WalletDirectoryScope {
  all('كل العملاء'),
  funded('لديهم رصيد'),
  frozen('محافظ مجمّدة'),
  awaitingRefund('بانتظار استرداد');

  const WalletDirectoryScope(this.label);

  final String label;

  bool matches(WalletDirectoryEntry entry) => switch (this) {
    WalletDirectoryScope.all => true,
    WalletDirectoryScope.funded => entry.balance > 0,
    WalletDirectoryScope.frozen => entry.walletStatus == WalletStatus.frozen,
    WalletDirectoryScope.awaitingRefund => entry.pendingRefunds > 0,
  };
}

/// Directory ordering. Balance first because the question the directory is
/// opened with is almost always "who are we holding money for".
enum WalletDirectorySort {
  balance('الأعلى رصيداً'),
  activity('الأحدث نشاطاً'),
  entries('الأكثر حركة'),
  name('الاسم أبجدياً');

  const WalletDirectorySort(this.label);

  final String label;

  int compare(WalletDirectoryEntry a, WalletDirectoryEntry b) => switch (this) {
    WalletDirectorySort.balance => b.balance.compareTo(a.balance),
    // A customer with no activity at all sorts last rather than first: a
    // null date is "never", and "never" is not recent.
    WalletDirectorySort.activity => switch ((
      a.lastActivityAt,
      b.lastActivityAt,
    )) {
      (null, null) => 0,
      (null, _) => 1,
      (_, null) => -1,
      (final left?, final right?) => right.compareTo(left),
    },
    WalletDirectorySort.entries => b.entryCount.compareTo(a.entryCount),
    WalletDirectorySort.name => a.displayName.compareTo(b.displayName),
  };
}

/// The directory tab's narrowing, minus the search term.
///
/// The term is not held here because it is not a client-side predicate: it goes
/// to the RPC, and mirroring it into this object would give the module two
/// copies of one string to keep in step.
class WalletDirectoryFilters {
  final WalletDirectoryScope scope;
  final WalletDirectorySort sort;

  const WalletDirectoryFilters({
    this.scope = WalletDirectoryScope.all,
    this.sort = WalletDirectorySort.balance,
  });

  /// Drives the toolbar's reset badge. The sort changes the order, not the
  /// population, so it is deliberately not counted.
  int get activeCount => scope == WalletDirectoryScope.all ? 0 : 1;

  WalletDirectoryFilters copyWith({
    WalletDirectoryScope? scope,
    WalletDirectorySort? sort,
  }) => WalletDirectoryFilters(
    scope: scope ?? this.scope,
    sort: sort ?? this.sort,
  );

  List<WalletDirectoryEntry> apply(List<WalletDirectoryEntry> rows) {
    final filtered = rows.where(scope.matches).toList()..sort(sort.compare);
    return filtered;
  }
}

/// Activity ordering, over the page the ledger RPC returned.
///
/// «الأقدم أولاً» reorders that page — it does not reach further back, and the
/// cap notice under the list says so. Offering it anyway is right: an operator
/// reading one day's movements wants them in the order they happened.
enum WalletActivitySort {
  newest('الأحدث أولاً'),
  oldest('الأقدم أولاً'),
  amount('الأكبر مبلغاً');

  const WalletActivitySort(this.label);

  final String label;

  int compare(WalletTransaction a, WalletTransaction b) => switch (this) {
    WalletActivitySort.newest => b.createdAt.compareTo(a.createdAt),
    WalletActivitySort.oldest => a.createdAt.compareTo(b.createdAt),
    WalletActivitySort.amount => b.amount.abs().compareTo(a.amount.abs()),
  };

  List<WalletTransaction> apply(List<WalletTransaction> rows) =>
      [...rows]..sort(compare);
}

/// Which refunds the queue is showing.
///
/// [open] is the working queue — the rows that still need a decision — and it
/// is what the tab opens on. The other three exist because "did we already
/// refund this?" is asked as often as "what is waiting", and before this the
/// module could not answer it at all.
enum WalletRefundScope {
  open('بانتظار القرار'),
  settled('منفّذة'),
  refused('مرفوضة'),
  all('كل الطلبات');

  const WalletRefundScope(this.label);

  final String label;

  bool matches(RefundRequest refund) => switch (this) {
    WalletRefundScope.open => refund.isOpen,
    WalletRefundScope.settled => refund.status == RefundStatus.settled,
    WalletRefundScope.refused =>
      refund.status == RefundStatus.rejected ||
          refund.status == RefundStatus.failed ||
          refund.status == RefundStatus.cancelled,
    WalletRefundScope.all => true,
  };
}

/// Which side filed the request. `refund_requests.source` is a two-valued
/// column, so this is the whole axis rather than a selection from it.
enum WalletRefundSource {
  all('كل المصادر'),
  client('من تطبيق العميل'),
  dashboard('من لوحة التحكم');

  const WalletRefundSource(this.label);

  final String label;

  bool matches(RefundRequest refund) => switch (this) {
    WalletRefundSource.all => true,
    WalletRefundSource.client => refund.fromClient,
    WalletRefundSource.dashboard => !refund.fromClient,
  };
}

enum WalletRefundSort {
  newest('الأحدث أولاً'),
  oldest('الأقدم أولاً'),
  amount('الأكبر مبلغاً');

  const WalletRefundSort(this.label);

  final String label;

  int compare(RefundRequest a, RefundRequest b) => switch (this) {
    WalletRefundSort.newest => b.createdAt.compareTo(a.createdAt),
    WalletRefundSort.oldest => a.createdAt.compareTo(b.createdAt),
    WalletRefundSort.amount => b.effectiveAmount.compareTo(a.effectiveAmount),
  };
}

/// The refund queue's narrowing.
///
/// Every predicate here runs on the client, over the queue the module already
/// holds — the fetch is one capped, ordered read of `refund_requests` and these
/// are slices of it. That is why the counts on the KPI tiles and the tab strip
/// are computed from the same list: there is no second query to disagree with.
class WalletRefundFilters {
  final String search;
  final WalletRefundScope scope;
  final WalletRefundSource source;

  /// Where the money went. Null is "الكل"; picking a destination naturally
  /// excludes the undecided rows, which have none yet.
  final RefundSettlement? settlement;

  final WalletRefundSort sort;

  const WalletRefundFilters({
    this.search = '',
    this.scope = WalletRefundScope.open,
    this.source = WalletRefundSource.all,
    this.settlement,
    this.sort = WalletRefundSort.newest,
  });

  /// The scope counts as active only when it is not the queue's own default —
  /// «بانتظار القرار» is the tab's resting state, not a narrowing the operator
  /// has to be reminded of.
  int get activeCount =>
      (search.trim().isEmpty ? 0 : 1) +
      (scope == WalletRefundScope.open ? 0 : 1) +
      (source == WalletRefundSource.all ? 0 : 1) +
      (settlement == null ? 0 : 1);

  WalletRefundFilters copyWith({
    String? search,
    WalletRefundScope? scope,
    WalletRefundSource? source,
    RefundSettlement? settlement,
    WalletRefundSort? sort,
    bool clearSettlement = false,
  }) => WalletRefundFilters(
    search: search ?? this.search,
    scope: scope ?? this.scope,
    source: source ?? this.source,
    settlement: clearSettlement ? null : (settlement ?? this.settlement),
    sort: sort ?? this.sort,
  );

  List<RefundRequest> apply(List<RefundRequest> rows) {
    final term = PlaceSearchText.normalize(search);
    final filtered =
        rows
            .where(scope.matches)
            .where(source.matches)
            .where(
              (refund) => settlement == null || refund.settlement == settlement,
            )
            .where((refund) => _matchesSearch(refund, term))
            .toList()
          ..sort(sort.compare);
    return filtered;
  }

  /// The same normaliser the route catalogue searches with: an operator typing
  /// «احمد» must find «أحمد», and typing «١٢٣» must find booking `123`.
  static bool _matchesSearch(RefundRequest refund, String term) {
    if (term.isEmpty) return true;
    for (final field in [
      refund.clientName,
      refund.clientPhone,
      refund.bookingNumber,
      refund.reason,
      refund.categoryLabel,
      refund.requestedByName,
      refund.reviewedByName,
    ]) {
      if (field == null) continue;
      if (PlaceSearchText.containsNormalized(field, term)) return true;
    }
    return false;
  }
}

/// How many rows each of the three tabs shows at once.
///
/// One number, not three: the tabs sit behind one strip, and an operator who
/// pages through الحركات and then opens الاسترداد should not find the page
/// length changed underneath them.
const int walletPageSize = 10;

/// The slice of [rows] the operator is on, with [page] clamped by
/// [walletPageIndex] so a filter that shrinks the list under the current page
/// lands on the last page rather than on nothing.
List<T> walletPageOf<T>(List<T> rows, int page) {
  final start = walletPageIndex(rows.length, page) * walletPageSize;
  return rows.skip(start).take(walletPageSize).toList();
}

/// The page index actually in view — [page] clamped to what [total] supports.
int walletPageIndex(int total, int page) {
  final pages = walletPageCount(total);
  return page.clamp(0, pages - 1);
}

/// How many pages [total] rows make. Always at least one, so an empty list
/// still has a page to be on.
int walletPageCount(int total) =>
    total == 0 ? 1 : (total / walletPageSize).ceil();
