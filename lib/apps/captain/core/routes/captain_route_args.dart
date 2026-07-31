import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';

/// Typed arguments for the captain routes that carry more than a trip id.
///
/// Named routes hand arguments over as `Object?`, so the cast has to happen
/// somewhere. Keeping these classes here — rather than passing bare maps —
/// means `CaptainAppRouter` is the *only* place that casts, and the
/// `CaptainNav` extension gives every call site back its compile-time types.

/// Arguments for [CaptainRoutes.reportIncident].
class ReportIncidentArgs {
  const ReportIncidentArgs({
    required this.tripId,
    this.initialType = IncidentType.delay,
  });

  final String tripId;

  /// Preselects the incident kind — the SOS control opens this screen already
  /// switched to [IncidentType.emergency].
  final IncidentType initialType;
}
