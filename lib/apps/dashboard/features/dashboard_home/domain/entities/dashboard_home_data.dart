class DashboardHomeData {
  final List<DashboardMetric> metrics;
  final List<DashboardQueueItem> recentBookings;
  final List<DashboardQueueItem> tripsNeedingAction;
  final List<DashboardQueueItem> delayedDrivers;
  final List<DashboardQueueItem> openTickets;

  const DashboardHomeData({
    required this.metrics,
    required this.recentBookings,
    required this.tripsNeedingAction,
    required this.delayedDrivers,
    required this.openTickets,
  });
}

class DashboardMetric {
  final String label;
  final String value;
  final String note;

  const DashboardMetric({
    required this.label,
    required this.value,
    required this.note,
  });
}

class DashboardQueueItem {
  final String title;
  final String subtitle;
  final String status;

  const DashboardQueueItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });
}
