import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';

import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// The at-a-glance headline of the operations center: how many trips are
/// running, how many are late leaving, how many have lost their tracking feed,
/// and how many incidents are open. Every number is a live count off the
/// snapshot — nothing is estimated.
///
/// The four tiles are ordered by how urgently they demand an operator's hands:
/// running trips are context, everything after it is a potential intervention.
class LiveOpsSummaryBar extends StatelessWidget {
  final LiveOpsSnapshot snapshot;

  /// Trips whose feed is not [TrackingHealth.live], counted by the feed Bloc.
  ///
  /// Passed in rather than derived from [snapshot] so that this tile and the
  /// badges on the cards below it are computed from the same positions. Deriving
  /// it here would count the roster's seed fixes and could report "0 متعثّر"
  /// while three cards visibly read «غير متصلة».
  final int atRisk;

  final DateTime now;

  const LiveOpsSummaryBar({
    super.key,
    required this.snapshot,
    required this.atRisk,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final openIncidents = snapshot.openIncidentCount;
    final unacknowledged = snapshot.unacknowledgedCount;
    final overdue = snapshot.overdueCount(now);

    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'على الطريق',
          value: '${snapshot.inProgressCount}',
          icon: Icons.directions_bus_filled_rounded,
          color: context.status(AppStatusTone.success).ink,
          detail: 'رحلات جارية الآن',
        ),
        DashboardKpiCard(
          label: 'تأخّر الانطلاق',
          value: '$overdue',
          icon: Icons.running_with_errors_rounded,
          color: overdue > 0
              ? context.status(AppStatusTone.error).ink
              : context.status(AppStatusTone.neutral).ink,
          detail: overdue > 0
              ? 'لم تنطلق بعد موعدها'
              : 'من ${snapshot.boardingCount} في الصعود',
        ),
        DashboardKpiCard(
          label: 'تتبع متعثّر',
          value: '$atRisk',
          icon: Icons.location_off_rounded,
          color: atRisk > 0
              ? context.status(AppStatusTone.warning).ink
              : context.status(AppStatusTone.neutral).ink,
          detail: 'إشارة متأخرة أو مفقودة',
        ),
        DashboardKpiCard(
          label: 'بلاغات مفتوحة',
          value: '$openIncidents',
          icon: Icons.report_rounded,
          color: snapshot.hasCriticalIncident
              ? context.status(AppStatusTone.error).ink
              : (openIncidents > 0
                    ? context.status(AppStatusTone.warning).ink
                    : context.status(AppStatusTone.neutral).ink),

          detail: snapshot.hasCriticalIncident
              ? 'بلاغ طوارئ نشط'
              : (unacknowledged > 0
                    ? '$unacknowledged لم يُستلم بعد'
                    : 'قيد المعالجة'),
        ),
      ],
    );
  }
}
