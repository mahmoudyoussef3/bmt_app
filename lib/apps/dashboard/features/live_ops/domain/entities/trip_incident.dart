/// An incident or SOS report a captain filed from the road, surfaced to the
/// operations desk for acknowledgement and resolution.
///
/// Backed by `driver_trip_reports` — the same table the Captain App writes to
/// (`supabase_incident_datasource.dart`). The dashboard is the *reader/resolver*
/// side of that table; office isolation is enforced by the
/// `driver_trip_reports_office_manage` RLS policy, so a row only reaches this
/// entity when its trip belongs to the signed-in office.
library;

/// The kind of problem reported. Values map 1:1 onto the `report_type` strings
/// the Captain App writes, plus the legacy shorthand the original schema
/// documented (`flat_tire`, `passenger_no_show`, `traffic`) so historical rows
/// never fall through to [other] silently.
enum IncidentType {
  emergency('طوارئ / نجدة'),
  vehicleIssue('عطل في المركبة'),
  routeBlockage('إغلاق الطريق'),
  passengerIssue('مشكلة مع راكب'),
  delay('تأخير'),
  other('أخرى');

  const IncidentType(this.label);

  final String label;

  static IncidentType fromDb(String value) => switch (value) {
    'emergency' || 'sos' => IncidentType.emergency,
    'vehicle_issue' || 'flat_tire' || 'breakdown' => IncidentType.vehicleIssue,
    'route_blockage' ||
    'traffic' ||
    'road_closed' => IncidentType.routeBlockage,
    'passenger_issue' || 'passenger_no_show' => IncidentType.passengerIssue,
    'delay' => IncidentType.delay,
    _ => IncidentType.other,
  };
}

/// How loudly the incident should shout for attention. Derived from the type —
/// the captain does not pick a severity, so the desk gets a consistent triage
/// order regardless of how each captain phrases things.
enum IncidentSeverity { critical, warning, info }

/// The incident's place in the operations desk's workflow.
///
/// Mirrors the `driver_trip_reports_status_check` allowlist added in migration
/// `20260727090000`. [acknowledged] is the state that makes a shared desk work:
/// it says a human already owns this report, so a second operator does not call
/// the same captain about the same problem.
enum IncidentStatus {
  pending('جديد'),
  acknowledged('قيد المعالجة'),
  resolved('تم الحل'),
  dismissed('تم الاستبعاد');

  const IncidentStatus(this.label);

  final String label;

  String get db => switch (this) {
    IncidentStatus.pending => 'pending',
    IncidentStatus.acknowledged => 'acknowledged',
    IncidentStatus.resolved => 'resolved',
    IncidentStatus.dismissed => 'dismissed',
  };

  /// Unknown values read as [pending] rather than being dropped: an incident the
  /// desk cannot classify must still be visible and actionable.
  static IncidentStatus fromDb(String value) => switch (value) {
    'acknowledged' => IncidentStatus.acknowledged,
    'resolved' => IncidentStatus.resolved,
    'dismissed' => IncidentStatus.dismissed,
    _ => IncidentStatus.pending,
  };

  /// Whether [next] is a legal move from this state.
  ///
  /// The lifecycle is deliberately one-directional — nothing returns to
  /// [pending], because "unacknowledged again" is not a real operational state
  /// and would erase the record of who took ownership. A [pending] report may be
  /// closed directly (a duplicate needs no acknowledgement round-trip), and a
  /// closed report is terminal.
  bool canTransitionTo(IncidentStatus next) => switch (this) {
    IncidentStatus.pending =>
      next == IncidentStatus.acknowledged ||
          next == IncidentStatus.resolved ||
          next == IncidentStatus.dismissed,
    IncidentStatus.acknowledged =>
      next == IncidentStatus.resolved || next == IncidentStatus.dismissed,
    IncidentStatus.resolved || IncidentStatus.dismissed => false,
  };

  /// Terminal states — the report has left the queue.
  bool get isClosed =>
      this == IncidentStatus.resolved || this == IncidentStatus.dismissed;
}

class TripIncident {
  final String id;
  final String tripId;
  final IncidentType type;
  final String description;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// When an operator took ownership. Null while [IncidentStatus.pending], and
  /// also null for a report closed straight from pending.
  final DateTime? acknowledgedAt;

  /// The operator's account of what was done, captured when closing the report.
  final String resolutionNote;

  /// Context resolved from the incident's trip so the desk can act without
  /// opening the trip first. Any of these may be empty for an orphaned row.
  final String routeName;
  final String driverName;
  final String vehicleLabel;
  final String tripDate;
  final String departureTime;

  const TripIncident({
    required this.id,
    required this.tripId,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.acknowledgedAt,
    this.resolutionNote = '',
    this.routeName = '',
    this.driverName = '',
    this.vehicleLabel = '',
    this.tripDate = '',
    this.departureTime = '',
  });

  /// Still in the desk's queue — either untouched or owned but not yet closed.
  /// This is what the Live Ops queue renders, so acknowledging a report keeps it
  /// visible (with its new state) instead of making it vanish mid-handling.
  bool get isOpen => !status.isClosed;

  /// Untouched: nobody has taken ownership yet.
  bool get isPending => status == IncidentStatus.pending;

  bool get isAcknowledged => status == IncidentStatus.acknowledged;

  /// How long the report has been open at [now] — the desk's ageing signal.
  Duration ageAt(DateTime now) {
    final age = now.difference(createdAt);
    return age.isNegative ? Duration.zero : age;
  }

  IncidentSeverity get severity => switch (type) {
    IncidentType.emergency => IncidentSeverity.critical,
    IncidentType.vehicleIssue ||
    IncidentType.routeBlockage => IncidentSeverity.warning,
    IncidentType.passengerIssue ||
    IncidentType.delay ||
    IncidentType.other => IncidentSeverity.info,
  };
}
