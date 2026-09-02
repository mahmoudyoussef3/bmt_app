import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../cubit/captain_requests_state.dart';
import '../models/captain_request_queue_tab.dart';
import 'captain_requests_format.dart';

/// طلبات الكباتن' headline counts.
///
/// ## Why three of the four are also tabs
///
/// "٢ بانتظار القرار" is only useful if the next question — *which two* — is
/// one press away. Each of the first three tiles opens the
/// [CaptainRequestQueueTab] that produced it, so the number, the tab under it
/// and the queue behind them can never disagree: they are the same predicate,
/// asked of the same function.
///
/// The fourth, متوسط زمن الرد, is a derived measure rather than a queue — there
/// is no "list of average" to open — so it carries no tap. It reads «—» when no
/// decided request records a `reviewed_at`, because "we have no timings" and
/// "we answer instantly" are different claims.
///
/// ## Why the accepted/rejected tiles are all-time, not this month
///
/// The design's tiles are scoped «هذا الشهر», which needs a decision date on
/// every decided row. `captain_requests.reviewed_at` is nullable and older rows
/// predate it, so a month-scoped count would silently under-report a real
/// approval as zero. All-time counts are what the table can actually stand
/// behind — and they keep the tile↔tab rule above intact, since the tabs are
/// all-time too.
class CaptainRequestsSummary extends StatelessWidget {
  const CaptainRequestsSummary({
    super.key,
    required this.state,
    required this.onOpenQueue,
  });

  final CaptainRequestsLoaded state;

  /// Opens one queue. Passed in rather than reached for through the element
  /// tree, so this strip stays renderable without a cubit above it.
  final ValueChanged<CaptainRequestQueueTab> onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final (responseValue, responseUnit) = CaptainRequestsFormat.responseTime(
      state.averageResponse,
    );

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        _tile(
          context,
          tab: CaptainRequestQueueTab.pending,
          label: 'بانتظار القرار',
          value: state.pendingCount,
          icon: Icons.how_to_reg_outlined,
          detail: 'طلبات لم يُبتّ فيها بعد',
          // The one tile that changes colour with its own number: an empty
          // queue is the good news, and saying so in amber would train the
          // operator to stop reading it.
          tone: state.pendingCount > 0
              ? AppStatusTone.warning
              : AppStatusTone.neutral,
          hint: 'عرض الطلبات بانتظار القرار',
        ),
        _tile(
          context,
          tab: CaptainRequestQueueTab.approved,
          label: 'مقبولون',
          value: state.approvedCount,
          icon: Icons.verified_user_outlined,
          detail: 'انضموا لفريق السائقين',
          tone: AppStatusTone.success,
          hint: 'عرض الطلبات المقبولة',
        ),
        _tile(
          context,
          tab: CaptainRequestQueueTab.rejected,
          label: 'مرفوضون',
          value: state.rejectedCount,
          icon: Icons.person_off_outlined,
          detail: 'مع بيان سبب الرفض',
          tone: AppStatusTone.neutral,
          hint: 'عرض الطلبات المرفوضة',
        ),
        DashboardKpiCard(
          label: 'متوسط زمن الرد',
          value: responseValue,
          icon: Icons.schedule_outlined,
          detail: responseUnit,
          color: DashboardColors.status(context, AppStatusTone.info).accent,
          emphasized: true,
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required CaptainRequestQueueTab tab,
    required String label,
    required int value,
    required IconData icon,
    required String detail,
    required AppStatusTone tone,
    required String hint,
  }) {
    return DashboardKpiCard(
      label: label,
      value: CaptainRequestsFormat.count(value),
      icon: icon,
      detail: detail,
      // The tone's `accent`, not its `ink`: a tile's fill is near-white, and
      // `ink` is the *container* ink, which on it reads as black type rather
      // than as a status.
      color: DashboardColors.status(context, tone).accent,
      emphasized: true,
      onTap: () => onOpenQueue(tab),
      tapHint: hint,
    );
  }
}
