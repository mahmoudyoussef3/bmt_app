import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import 'overview_kit.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// The jobs an owner starts from the overview.
///
/// ## Three honest limitations, all deliberate
///
/// **The one true deep link is not in here — it is in the hero.** The shell
/// owns a one-shot flag that opens the trip planner on top of the Trips screen,
/// and «رحلة جديدة» used to sit at the very foot of the page, below eight full
/// sections, as the first of nine equal tiles. An action nobody scrolls to is
/// not a shortcut, so it was promoted to a filled button in the brand band and
/// removed from this list rather than printed twice.
///
/// **Nothing else here is a deep link.** No equivalent one-shot flag exists for
/// the other eight, and inventing one would mean a new entry point into eight
/// modules for a shortcut. So each opens the screen that owns the action, where
/// its own "add" button is the next thing under the cursor, and the hint says
/// where it lands rather than promising a dialog it does not open.
///
/// **Actions the operator cannot perform are absent, not disabled.** The
/// [canOpen] predicate is the shell's own `role ∧ entitlement` check, so a
/// support agent never sees a wallet adjustment greyed out and a plan without
/// the wallet never sees one at all — the sidebar already carries the upgrade
/// conversation, and a dead button on the landing page is not a second place to
/// have it.
///
/// The tiles are the kit's record tile — the same object الرئيسية's attention
/// queue is built from — laid out on the kit's column rule. They were fixed
/// 172px boxes, which is the lane trap the design system documents: one Arabic
/// label wider than the lane and it clips.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onOpenModule,
    required this.canOpen,
  });

  final ValueChanged<String> onOpenModule;

  /// The shell's `role ∧ entitlement` gate for a route.
  final bool Function(String route) canOpen;

  @override
  Widget build(BuildContext context) {
    final actions = const <_QuickAction>[
      _QuickAction(
        label: 'مسار جديد',
        hint: 'المسارات',
        icon: DashboardIcons.routes,
        route: DashboardRoutes.routes,
      ),
      _QuickAction(
        label: 'حجز جديد',
        hint: 'الحجوزات',
        icon: DashboardIcons.bookings,
        route: DashboardRoutes.bookings,
      ),
      _QuickAction(
        label: 'مراجعة الإيصالات',
        hint: 'مراجعة المدفوعات',
        icon: DashboardIcons.paymentReview,
        route: DashboardRoutes.paymentVerification,
      ),
      _QuickAction(
        label: 'إضافة سائق',
        hint: 'السائقون',
        icon: DashboardIcons.captains,
        route: DashboardRoutes.drivers,
      ),
      _QuickAction(
        label: 'إضافة مركبة',
        hint: 'المركبات',
        icon: DashboardIcons.vehicle,
        route: DashboardRoutes.vehicles,
      ),
      _QuickAction(
        label: 'تسجيل استرداد',
        hint: 'محفظة العملاء',
        icon: DashboardIcons.wallet,
        route: DashboardRoutes.wallet,
      ),
      _QuickAction(
        label: 'منح كاش باك',
        hint: 'محفظة العملاء',
        icon: DashboardIcons.revenue,
        route: DashboardRoutes.wallet,
      ),
      _QuickAction(
        label: 'العمليات المباشرة',
        hint: 'متابعة الرحلات لحظياً',
        icon: DashboardIcons.liveOps,
        route: DashboardRoutes.liveOps,
      ),
    ].where((action) => canOpen(action.route)).toList();

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessQuickActions,
      icon: DashboardIcons.quickAction,
      title: 'إجراءات سريعة',
      subtitle: 'ابدأ أكثر المهام تكراراً من هنا',
      collapsedSummary: Text(
        '${actions.length} إجراء متاح',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: actions.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.locked,
              title: 'لا توجد إجراءات متاحة',
              message: 'صلاحيات حسابك لا تسمح بأي من الإجراءات السريعة.',
            )
          : OverviewTileGrid(
              rowHeight: 64,
              maxColumns: 2,
              children: [
                for (final action in actions)
                  OverviewRecordTile(
                    icon: action.icon,
                    title: action.label,
                    subtitle: action.hint,
                    tone: AppStatusTone.neutral,
                    onTap: () => onOpenModule(action.route),
                  ),
              ],
            ),
    );
  }
}

class _QuickAction {
  final String label;
  final String hint;
  final IconData icon;
  final String route;

  const _QuickAction({
    required this.label,
    required this.hint,
    required this.icon,
    required this.route,
  });
}
