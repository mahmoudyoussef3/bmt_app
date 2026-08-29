import '../../domain/entities/complaint.dart';
import '../cubit/tickets_state.dart';

/// The queues الشكاوى is worked through, in the order the work actually
/// arrives: what has run out of time first, then what nobody has picked up.
///
/// Same contract as [CustomerQueueTab] and [SubscriptionQueueTab] one section
/// over — a tab is a *predicate over the module's own filters*, never a second
/// copy of the list. Selection is derived from those filters rather than
/// stored, which is what keeps the strip and the «التصفية» dropdowns from ever
/// disagreeing: they are the same state read twice.
///
/// ## The strip owns two axes, not five
///
/// A tab sets exactly [TicketsLoaded.overdueOnly] and
/// [TicketsLoaded.filterStatus] and leaves the search text, the priority, the
/// category and the assignment alone — so switching queues never silently
/// drops what the agent typed. A combination no tab represents — "عاجلة غير
/// مسندة" — leaves no tab highlighted, which is the truthful answer; the
/// collapsed filter summary says what is in force in that case.
enum TicketQueueTab {
  /// Unresolved past the office's 24-hour promise. First, because it is the
  /// only queue where waiting costs something that cannot be recovered.
  overdue('متأخرة'),
  newTickets('جديدة'),
  underReview('قيد المراجعة'),
  resolved('تم الحل'),
  all('كل التذاكر');

  const TicketQueueTab(this.label);

  final String label;

  /// Queues that represent outstanding work, so the strip can keep them
  /// distinct even while the agent is looking at another tab.
  bool get isWorkQueue =>
      this == TicketQueueTab.overdue || this == TicketQueueTab.newTickets;

  /// The tab's own count, straight from the counters the queue already
  /// derives. No tab shows a number the module did not already report on a
  /// KPI tile.
  int countIn(TicketsLoaded state) => switch (this) {
    TicketQueueTab.all => state.tickets.length,
    TicketQueueTab.overdue => state.delayedCount,
    TicketQueueTab.newTickets => state.newCount,
    TicketQueueTab.underReview => state.underReviewCount,
    TicketQueueTab.resolved => state.resolvedCount,
  };

  bool get _overdueOnly => this == TicketQueueTab.overdue;

  TicketStatus? get _status => switch (this) {
    TicketQueueTab.newTickets => TicketStatus.submitted,
    TicketQueueTab.underReview => TicketStatus.underReview,
    TicketQueueTab.resolved => TicketStatus.resolved,
    TicketQueueTab.overdue || TicketQueueTab.all => null,
  };

  bool isSelectedBy(TicketsLoaded state) =>
      state.overdueOnly == _overdueOnly && state.filterStatus == _status;
}
