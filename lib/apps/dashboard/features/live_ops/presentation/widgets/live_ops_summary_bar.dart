import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../domain/entities/live_ops_snapshot.dart';

/// The at-a-glance headline of the operations center: how many trips are
/// running, how many are late leaving, how many have lost their tracking feed,
/// and how many incidents are open. Every number is a live count off the
/// snapshot — nothing is estimated.
///
/// The four tiles are ordered by how urgently they demand an operator's hands:
/// running trips are context, everything after it is a potential intervention.
///
/// Drawn in Home's hero-KPI shape (`emphasized`) rather than the compact stat
/// row, for two reasons. It is the same reader looking at the same kind of
/// number one module away, and — the reason that matters — this strip is no
/// longer folded behind a «الملخص» toggle, so it is the first thing on the page
/// and has to carry the weight of one. No sparklines: the console keeps no
/// history of a live board, and a shape drawn from nothing would be a guess.
class LiveOpsSummaryBar extends StatelessWidget {
  final LiveOpsSnapshot snapshot;

  /// Trips whose feed is not [TrackingHealth.live], counted by the feed Bloc.
  ///
  /// Passed in rather than derived from [snapshot] so that this tile and the
  /// badges on the rows below it are computed from the same positions. Deriving
  /// it here would count the roster's seed fixes and could report "0 متعثّر"
  /// while three rows visibly read «غير متصلة».
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
    final palette = DashboardChartPalette.of(context);
    final openIncidents = snapshot.openIncidentCount;
    final unacknowledged = snapshot.unacknowledgedCount;
    final overdue = snapshot.overdueCount(now);
    final quiet = DashboardColors.mutedInk(context);

    return DashboardKpiGrid(
      // Home's stacked tile, minus the row its sparkline occupies. Home spends
      // 132px because three of its four tiles draw a week's shape along the
      // bottom; a live board keeps no history, so drawing that row here would
      // reserve 24px of nothing under every value.
      itemExtent: 108,
      children: [
        DashboardKpiCard(
          emphasized: true,
          label: 'على الطريق',
          value: '${snapshot.inProgressCount}',
          icon: DashboardIcons.liveOpsActive,
          color: palette.positive,
          detail: snapshot.boardingCount == 0
              ? 'رحلات جارية الآن'
              : '${snapshot.boardingCount} في الصعود',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'تأخّر الانطلاق',
          value: '$overdue',
          icon: Icons.running_with_errors_rounded,
          color: overdue > 0
              ? context.status(AppStatusTone.error).accent
              : quiet,
          detail: overdue > 0 ? 'لم تنطلق بعد موعدها' : 'كل الرحلات في موعدها',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'تتبع متعثّر',
          value: '$atRisk',
          icon: Icons.location_off_rounded,
          color: atRisk > 0
              ? context.status(AppStatusTone.warning).accent
              : quiet,
          detail: atRisk > 0 ? 'إشارة متأخرة أو مفقودة' : 'كل المركبات تبثّ',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'بلاغات مفتوحة',
          value: '$openIncidents',
          icon: DashboardIcons.incident,
          color: snapshot.hasCriticalIncident
              ? context.status(AppStatusTone.error).accent
              : (openIncidents > 0
                    ? context.status(AppStatusTone.warning).accent
                    : quiet),
          detail: snapshot.hasCriticalIncident
              ? 'بلاغ طوارئ نشط'
              : (unacknowledged > 0
                    ? '$unacknowledged لم يُستلم بعد'
                    : (openIncidents > 0
                          ? 'قيد المعالجة'
                          : 'لا شيء بانتظار الرد')),
        ),
      ],
    );
  }
}
