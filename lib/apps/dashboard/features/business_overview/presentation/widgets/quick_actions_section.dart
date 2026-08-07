import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Section 7 — the jobs an owner starts from the overview.
///
/// ## Two honest limitations, both deliberate
///
/// **Only "رحلة جديدة" is a true deep link.** The shell owns a one-shot flag
/// that opens the trip planner on top of the Trips screen; nothing equivalent
/// exists for the other eight, and inventing it would mean a new entry point
/// into eight modules for a shortcut. So the rest open the screen that owns the
/// action, where its own "add" button is the next thing under the cursor. The
/// labels say where they land rather than promising a dialog they do not open.
///
/// **Actions the operator cannot perform are absent, not disabled.** The
/// [canOpen] predicate is the shell's own `role ∧ entitlement` check, so a
/// support agent never sees a wallet adjustment greyed out and a plan without
/// the wallet never sees one at all — the sidebar already carries the upgrade
/// conversation, and a dead button on the landing page is not a second place
/// to have it.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onOpenModule,
    required this.canOpen,
    this.onCreateTrip,
  });

  final ValueChanged<String> onOpenModule;

  /// The shell's `role ∧ entitlement` gate for a route.
  final bool Function(String route) canOpen;

  /// Opens the trip planner directly. Provided by the shell, which owns
  /// navigation — this section only says *when*.
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'رحلة جديدة',
        hint: 'يفتح مخطط الرحلات',
        icon: DashboardIcons.trips,
        route: DashboardRoutes.trips,
        primary: true,
        onPressed: onCreateTrip,
      ),
      const _QuickAction(
        label: 'مسار جديد',
        hint: 'المسارات',
        icon: DashboardIcons.routes,
        route: DashboardRoutes.routes,
      ),
      const _QuickAction(
        label: 'إضافة سائق',
        hint: 'السائقون',
        icon: DashboardIcons.captains,
        route: DashboardRoutes.drivers,
      ),
      const _QuickAction(
        label: 'إضافة مركبة',
        hint: 'المركبات',
        icon: DashboardIcons.vehicle,
        route: DashboardRoutes.vehicles,
      ),
      const _QuickAction(
        label: 'حجز جديد',
        hint: 'الحجوزات',
        icon: DashboardIcons.bookings,
        route: DashboardRoutes.bookings,
      ),
      const _QuickAction(
        label: 'تسجيل استرداد',
        hint: 'محفظة العملاء',
        icon: DashboardIcons.wallet,
        route: DashboardRoutes.wallet,
      ),
      const _QuickAction(
        label: 'منح كاش باك',
        hint: 'محفظة العملاء',
        icon: DashboardIcons.revenue,
        route: DashboardRoutes.wallet,
      ),
      const _QuickAction(
        label: 'مراجعة الإيصالات',
        hint: 'مراجعة المدفوعات',
        icon: DashboardIcons.paymentReview,
        route: DashboardRoutes.paymentVerification,
      ),
      const _QuickAction(
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: actions.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.locked,
              title: 'لا توجد إجراءات متاحة',
              message: 'صلاحيات حسابك لا تسمح بأي من الإجراءات السريعة.',
            )
          : Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                for (final action in actions)
                  _ActionTile(
                    action: action,
                    onOpenModule: onOpenModule,
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

  /// The one action that is genuinely one click. Rendered filled.
  final bool primary;

  /// Supplied only where a real deep link exists; otherwise the tile opens
  /// [route].
  final VoidCallback? onPressed;

  const _QuickAction({
    required this.label,
    required this.hint,
    required this.icon,
    required this.route,
    this.primary = false,
    this.onPressed,
  });
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onOpenModule});

  final _QuickAction action;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final tint = action.primary ? scheme.primary : scheme.onSurfaceVariant;

    return SizedBox(
      width: 172,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: action.onPressed ?? () => onOpenModule(action.route),
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: action.primary
                  ? scheme.primary.withValues(alpha: 0.10)
                  : DashboardColors.well(context),
              borderRadius: radius,
              border: Border.all(
                color: action.primary
                    ? scheme.primary.withValues(alpha: 0.38)
                    : DashboardColors.border(context),
              ),
            ),
            child: Row(
              children: [
                Icon(action.icon, size: 20, color: tint),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        action.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
