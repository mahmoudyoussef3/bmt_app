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

/// Container/on-container colour pair for a tracking-health state.
({Color container, Color on}) trackingHealthColors(TrackingHealth health) {
  return switch (health) {
    TrackingHealth.live => (
      container: AppStatusColors.successContainer,
      on: AppStatusColors.onSuccessContainer,
    ),
    TrackingHealth.stale => (
      container: AppStatusColors.warningContainer,
      on: AppStatusColors.onWarningContainer,
    ),
    TrackingHealth.offline => (
      container: AppStatusColors.errorContainer,
      on: AppStatusColors.onErrorContainer,
    ),
    TrackingHealth.unknown => (
      container: AppStatusColors.neutralContainer,
      on: AppStatusColors.onNeutralContainer,
    ),
  };
}

/// Container/on-container colour pair for an incident severity.
({Color container, Color on}) incidentSeverityColors(IncidentSeverity s) {
  return switch (s) {
    IncidentSeverity.critical => (
      container: AppStatusColors.errorContainer,
      on: AppStatusColors.onErrorContainer,
    ),
    IncidentSeverity.warning => (
      container: AppStatusColors.warningContainer,
      on: AppStatusColors.onWarningContainer,
    ),
    IncidentSeverity.info => (
      container: AppStatusColors.infoContainer,
      on: AppStatusColors.onInfoContainer,
    ),
  };
}

IconData incidentTypeIcon(IncidentType type) => switch (type) {
  IncidentType.emergency => Icons.sos_rounded,
  IncidentType.vehicleIssue => Icons.build_rounded,
  IncidentType.routeBlockage => Icons.dangerous_rounded,
  IncidentType.passengerIssue => Icons.person_off_rounded,
  IncidentType.delay => Icons.schedule_rounded,
  IncidentType.other => Icons.report_gmailerrorred_rounded,
};
