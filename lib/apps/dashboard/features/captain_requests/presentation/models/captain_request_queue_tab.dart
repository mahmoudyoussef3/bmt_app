import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_state.dart';

/// The queues طلبات الكباتن is worked through, in the order the work actually
/// arrives: what is waiting on a decision first, then what has already been
/// decided.
///
/// Same contract as [TicketQueueTab] one section over — a tab is a *predicate
/// over the module's own filters*, never a second copy of the list. Selection
/// is derived from those filters rather than stored, which is what keeps the
/// strip and the «الحالة» dropdown from ever disagreeing: they are the same
/// state read twice.
///
/// ## The strip owns one axis
///
/// A tab sets exactly [CaptainRequestsLoaded.filterStatus] and leaves the
/// search text alone, so switching queues never drops what the operator typed.
enum CaptainRequestQueueTab {
  /// Requests nobody has answered. First, because it is the only queue where
  /// waiting costs a driver a working week.
  pending('بانتظار القرار'),
  approved('مقبول'),
  rejected('مرفوض'),
  all('كل الطلبات');

  const CaptainRequestQueueTab(this.label);

  final String label;

  /// The one queue that represents outstanding work, so the strip can keep it
  /// distinct even while the operator is looking at another tab.
  bool get isWorkQueue => this == CaptainRequestQueueTab.pending;

  /// The status this tab narrows to, or null for «كل الطلبات».
  CaptainRequestStatus? get status => switch (this) {
    CaptainRequestQueueTab.pending => CaptainRequestStatus.pending,
    CaptainRequestQueueTab.approved => CaptainRequestStatus.approved,
    CaptainRequestQueueTab.rejected => CaptainRequestStatus.rejected,
    CaptainRequestQueueTab.all => null,
  };

  /// The tab's own count, straight from the counters the queue already
  /// derives. No tab shows a number the module did not already report on a
  /// KPI tile.
  int countIn(CaptainRequestsLoaded state) => switch (this) {
    CaptainRequestQueueTab.pending => state.pendingCount,
    CaptainRequestQueueTab.approved => state.approvedCount,
    CaptainRequestQueueTab.rejected => state.rejectedCount,
    CaptainRequestQueueTab.all => state.requests.length,
  };

  bool isSelectedBy(CaptainRequestsLoaded state) =>
      state.filterStatus == status;
}
