import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../cubit/tickets_state.dart';
import '../models/ticket_queue_tab.dart';
import 'tickets_format.dart';

/// الشكاوى' headline counts.
///
/// ## Why four, and why each one is also a tab
///
/// "٣ تذاكر متأخرة" is only useful if the next question — *which three* — is
/// one press away. Every tile opens the [TicketQueueTab] that produced it, so
/// the number, the tab under it and the queue behind them can never disagree:
/// they are the same predicate, asked of the same function.
///
/// Four tiles in one row, in the same [DashboardKpiGrid] shape العملاء and
/// الاشتراكات wear, so an operator moving between the two sidebar sections
/// keeps the same header.
///
/// ## Why there is no trend on any of them
///
/// A trend needs a comparable prior period, and the support desk stores no
/// historical snapshot of its own queue. Drawing "+12%" from an arithmetic the
/// database cannot support is the fabrication this console refuses elsewhere.
class SummaryStats extends StatelessWidget {
  final TicketsLoaded state;

  /// Opens one queue. Passed in rather than reached for through the element
  /// tree, so this strip stays renderable without a cubit above it.
  final ValueChanged<TicketQueueTab> onOpenQueue;

  const SummaryStats({
    super.key,
    required this.state,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        _tile(
          context,
          tab: TicketQueueTab.newTickets,
          label: 'تذاكر جديدة',
          value: state.newCount,
          icon: Icons.mark_email_unread_outlined,
          detail: 'لم يبدأ العمل عليها بعد',
          tone: AppStatusTone.info,
          hint: 'عرض التذاكر الجديدة',
        ),
        _tile(
          context,
          tab: TicketQueueTab.underReview,
          label: 'قيد المراجعة',
          value: state.underReviewCount,
          icon: Icons.pending_actions_outlined,
          detail: 'مفتوحة على مكتب موظف',
          tone: AppStatusTone.warning,
          hint: 'عرض التذاكر قيد المراجعة',
        ),
        _tile(
          context,
          tab: TicketQueueTab.resolved,
          label: 'تم الحل',
          value: state.resolvedCount,
          icon: Icons.check_circle_outline_rounded,
          detail: 'بانتظار الإغلاق النهائي',
          tone: AppStatusTone.success,
          hint: 'عرض التذاكر التي تم حلها',
        ),
        _tile(
          context,
          tab: TicketQueueTab.overdue,
          label: 'متأخرة',
          value: state.delayedCount,
          icon: Icons.running_with_errors_outlined,
          detail: 'أكثر من ٢٤ ساعة بلا حل',
          // The one tile that changes colour with its own number: an empty
          // late queue is the good news, and saying so in red would train the
          // agent to stop reading it.
          tone: state.delayedCount > 0
              ? AppStatusTone.error
              : AppStatusTone.neutral,
          hint: 'عرض التذاكر المتأخرة',
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required TicketQueueTab tab,
    required String label,
    required int value,
    required IconData icon,
    required String detail,
    required AppStatusTone tone,
    required String hint,
  }) {
    return DashboardKpiCard(
      label: label,
      value: TicketsFormat.count(value),
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
