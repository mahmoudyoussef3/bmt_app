/// The orderings طلبات الكباتن is read in.
///
/// Every key is a column the table also offers, so the pinned control in the
/// toolbar and the sortable headers drive one value — the rule every list
/// module in this console follows.
enum CaptainRequestSort {
  /// Default. A joining queue is worked newest-first: the request that arrived
  /// this morning is the one the office has not answered yet.
  requestedAt('تاريخ الطلب'),
  name('اسم السائق'),
  reviewedAt('تاريخ القرار');

  const CaptainRequestSort(this.label);

  final String label;
}
