import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/captain_request.dart';

/// The same 6px-rect [DashboardStatusChip] every other module's table uses for
/// status.
///
/// Public because the table and the card list the queue falls back to below
/// [kDashboardTableBreakpoint] show the same badge — a status that reads one
/// way in the table and another on a card is the drift this pass removed. It
/// used to be a private `_StatusBadge` inside the card, blending
/// `scheme.tertiary`/`scheme.error` by hand instead of going through the
/// console's six-tone system.
class CaptainRequestStatusBadge extends StatelessWidget {
  const CaptainRequestStatusBadge({super.key, required this.status});

  final CaptainRequestStatus status;

  AppStatusTone get _tone => switch (status) {
    CaptainRequestStatus.pending => AppStatusTone.warning,
    CaptainRequestStatus.approved => AppStatusTone.success,
    CaptainRequestStatus.rejected => AppStatusTone.error,
  };

  @override
  Widget build(BuildContext context) {
    final tone = context.status(_tone);
    return DashboardStatusChip(
      label: status.label,
      color: tone.tint,
      textColor: tone.ink,
    );
  }
}
