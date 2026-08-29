/// How the support queue is ordered.
///
/// Lifted out of [TicketsTable]'s private state so the pinned
/// [DashboardSortControl] in the toolbar and the sortable column headers drive
/// the *same* value. While the table owned it privately, the ordering was a
/// control the agent could only reach by finding the right column header —
/// and the toolbar could not state what the queue was sorted by.
enum TicketSort {
  /// The support queue's real question is "what is about to breach", which is
  /// why this is the default rather than the creation date.
  sla('المهلة'),
  createdAt('تاريخ الإنشاء'),
  priority('الأولوية'),
  client('العميل'),
  ticketNumber('رقم التذكرة');

  const TicketSort(this.label);

  final String label;
}

/// Whether a ticket is on someone's desk. The third axis the agent narrows by
/// after status and priority — "ما الذي لم يلتقطه أحد بعد".
enum TicketAssignment {
  any('الكل'),
  unassigned('غير مسندة'),
  assigned('مسندة');

  const TicketAssignment(this.label);

  final String label;
}
