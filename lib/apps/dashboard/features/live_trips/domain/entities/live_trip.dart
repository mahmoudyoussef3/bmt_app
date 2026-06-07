enum LiveTripAlertType {
  delay('تأخير'),
  suddenStop('توقف مفاجئ'),
  complaint('شكوى'),
  routeDeviation('خروج عن المسار');

  final String label;

  const LiveTripAlertType(this.label);
}

class LiveTrip {
  final String id;
  final String route;
  final String driver;
  final String driverStatus;
  final String vehicle;
  final int passengersCount;
  final int progress;
  final String eta;
  final String currentStation;
  final String nextStation;
  final List<LiveTripTimelineItem> timeline;
  final List<LiveTripAlert> alerts;

  const LiveTrip({
    required this.id,
    required this.route,
    required this.driver,
    required this.driverStatus,
    required this.vehicle,
    required this.passengersCount,
    required this.progress,
    required this.eta,
    required this.currentStation,
    required this.nextStation,
    required this.timeline,
    required this.alerts,
  });
}

class LiveTripTimelineItem {
  final String title;
  final String time;
  final String status;
  final bool done;

  const LiveTripTimelineItem({
    required this.title,
    required this.time,
    required this.status,
    required this.done,
  });
}

class LiveTripAlert {
  final String id;
  final LiveTripAlertType type;
  final String message;
  final String time;
  final bool urgent;

  const LiveTripAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.time,
    required this.urgent,
  });
}
