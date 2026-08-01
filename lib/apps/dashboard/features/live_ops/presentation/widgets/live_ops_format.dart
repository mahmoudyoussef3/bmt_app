import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import '../../domain/entities/trip_incident.dart';

/// Short Arabic "time ago" label, matching the dashboard's existing style
/// (`الآن` / `منذ N د/س/يوم`) but adding second-level granularity because
/// tracking freshness is measured in seconds, not minutes.
String liveOpsAgo(Duration d) {
  if (d.inSeconds < 10) return 'الآن';
  if (d.inSeconds < 60) return 'منذ ${d.inSeconds} ث';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} د';
  if (d.inHours < 24) return 'منذ ${d.inHours} س';
  return 'منذ ${d.inDays} يوم';
}

/// The semantic status role a tracking-health state maps to.
///
/// Returns a *tone*, not colours: the caller resolves it against the theme in
/// effect via `context.status(...)`. It used to return a fixed
/// container/on-container pair off the light constants, so the live-ops board
/// kept its pale badges on a slate page.
AppStatusTone trackingHealthTone(TrackingHealth health) => switch (health) {
  TrackingHealth.live => AppStatusTone.success,
  TrackingHealth.stale => AppStatusTone.warning,
  TrackingHealth.offline => AppStatusTone.error,
  TrackingHealth.unknown => AppStatusTone.neutral,
};

/// The semantic status role an incident severity maps to.
AppStatusTone incidentSeverityTone(IncidentSeverity s) => switch (s) {
  IncidentSeverity.critical => AppStatusTone.error,
  IncidentSeverity.warning => AppStatusTone.warning,
  IncidentSeverity.info => AppStatusTone.info,
};

IconData incidentTypeIcon(IncidentType type) => switch (type) {
  IncidentType.emergency => Icons.sos_rounded,
  IncidentType.vehicleIssue => Icons.build_rounded,
  IncidentType.routeBlockage => Icons.dangerous_rounded,
  IncidentType.passengerIssue => Icons.person_off_rounded,
  IncidentType.delay => Icons.schedule_rounded,
  IncidentType.other => Icons.report_gmailerrorred_rounded,
};
