import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/widgets/alert_tile.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// "What should the office operator do right now?"
///
/// Two sources, in priority order:
///
/// 1. **Standing queues** derived from the loaded summary — trips with no
///    captain, receipts awaiting a decision, complaints going cold. This is the
///    operator's actual work list: counted from the same lists the modules
///    show, and unclearable until the work is done. Nothing here is
///    dismissible, because dismissing does not fix a bus with no driver.
/// 2. **Unread events** from [OperationalAlertsCubit] — the trigger-driven feed
///    that also powers the shell's bell. Shown only for types no queue above
///    already covers, so the operator is never told about the same pending
///    receipt twice in one panel.
class ActionRequiredSection extends StatelessWidget {
  const ActionRequiredSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final queues = summary.attentionItems;

    return BlocBuilder<OperationalAlertsCubit, OperationalAlertsState>(
      builder: (context, state) {
        final alerts = switch (state) {
          OperationalAlertsLoaded(:final alerts) =>
            alerts
                .where((a) => !a.isRead && !_coveredByQueue(a.type, summary))
                .toList()
              ..sort((a, b) => b.priority.index.compareTo(a.priority.index)),
          _ => const <OperationalAlert>[],
        };

        final total = queues.length + alerts.length;

        return DashboardPanel(
          sectionId: DashboardSectionIds.homeActionRequired,
          icon: total == 0 ? DashboardIcons.allClear : DashboardIcons.attention,
          title: 'يحتاج إلى إجراء',
          subtitle: total == 0 ? null : '$total بند بانتظارك',
          child: total == 0
              ? const DashboardEmptyState(
                  icon: DashboardIcons.allClear,
                  title: 'كل شيء تحت السيطرة',
                  message: 'لا يوجد ما يحتاج قراراً منك الآن.',
                )
              : Column(
                  children: [
                    for (final item in queues)
                      _QueueRow(item: item, onOpenModule: onOpenModule),
                    if (queues.isNotEmpty && alerts.isNotEmpty)
                      const Divider(height: AppSpacing.large),
                    for (final alert in alerts.take(4))
                      AlertTile(
                        alert: alert,
                        onTap: () {
                          context.read<OperationalAlertsCubit>().markAsRead(
                            alert.id,
                          );
                          final route = _routeForAlert(alert.type);
                          if (route != null) onOpenModule(route);
                        },
                        onMarkRead: () => context
                            .read<OperationalAlertsCubit>()
                            .markAsRead(alert.id),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// One standing queue: what it is, how many, and one tap to the screen that
/// clears it. The whole row is the target — an icon-sized button at the end of
/// a row is a miss waiting to happen.
class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item, required this.onOpenModule});

  final HomeAttentionItem item;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tone = switch (item.kind.severity) {
      HomeAttentionSeverity.urgent => palette.negative,
      HomeAttentionSeverity.warning => palette.warning,
      HomeAttentionSeverity.info => palette.active,
    };
    final spec = _specFor(item.kind);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: tone.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: () => onOpenModule(spec.route),
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: tone.withAlpha(50),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(spec.icon, size: 22, color: tone),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec.action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.count}',
                    style: text.titleMedium?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  DashboardIcons.openModule,
                  size: 20,
                  color: scheme.onSurfaceVariant.withAlpha(180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How a queue presents itself: what to call it, what clearing it means, where
/// that happens, and the glyph that carries it.
class _QueueSpec {
  final String title;
  final String action;
  final String route;
  final IconData icon;

  const _QueueSpec({
    required this.title,
    required this.action,
    required this.route,
    required this.icon,
  });
}

_QueueSpec _specFor(HomeAttentionKind kind) => switch (kind) {
  HomeAttentionKind.tripsWithoutCaptain => const _QueueSpec(
    title: 'رحلات بدون سائق',
    action: 'عيّن سائقاً قبل موعد القيام',
    route: DashboardRoutes.trips,
    icon: DashboardIcons.captain,
  ),
  HomeAttentionKind.staleTrips => const _QueueSpec(
    title: 'رحلات فات موعدها ومازالت مفتوحة',
    action: 'أغلقها أو ألغِها لتصحيح الأرقام',
    route: DashboardRoutes.trips,
    icon: DashboardIcons.time,
  ),
  HomeAttentionKind.paymentsAwaitingReview => const _QueueSpec(
    title: 'إيصالات بانتظار المراجعة',
    action: 'راجع الإيصال واقبله أو ارفضه',
    route: DashboardRoutes.paymentVerification,
    icon: DashboardIcons.paymentReview,
  ),
  HomeAttentionKind.urgentComplaints => const _QueueSpec(
    title: 'شكاوى عاجلة مفتوحة',
    action: 'رد على العميل اليوم',
    route: DashboardRoutes.tickets,
    icon: DashboardIcons.tickets,
  ),
  HomeAttentionKind.expiringDocuments => const _QueueSpec(
    title: 'مستندات أسطول تحتاج متابعة',
    action: 'جدّد المستندات قبل انتهائها',
    route: DashboardRoutes.fleet,
    icon: DashboardIcons.document,
  ),
  HomeAttentionKind.captainRequests => const _QueueSpec(
    title: 'طلبات انضمام سائقين',
    action: 'اقبل الطلب أو ارفضه',
    route: DashboardRoutes.captainRequests,
    icon: DashboardIcons.captainRequests,
  ),
  HomeAttentionKind.subscriptionsAwaitingPayment => const _QueueSpec(
    title: 'اشتراكات بانتظار الدفع',
    action: 'تابع تحصيل قيمة الباقة',
    route: DashboardRoutes.subscriptions,
    icon: DashboardIcons.subscriptions,
  ),
};

/// Whether a standing queue already says what this alert would say.
bool _coveredByQueue(OperationalAlertType type, DashboardHomeSummary summary) =>
    switch (type) {
      OperationalAlertType.paymentReview =>
        summary.pendingPaymentReviewsCount > 0,
      OperationalAlertType.captainRequest =>
        summary.pendingCaptainRequestsCount > 0,
      OperationalAlertType.supportTicket => summary.urgentComplaints.isNotEmpty,
      OperationalAlertType.refundRequest ||
      OperationalAlertType.tripCancelled ||
      OperationalAlertType.general => false,
    };

String? _routeForAlert(OperationalAlertType type) => switch (type) {
  OperationalAlertType.paymentReview => DashboardRoutes.paymentVerification,
  OperationalAlertType.captainRequest => DashboardRoutes.captainRequests,
  OperationalAlertType.supportTicket => DashboardRoutes.tickets,
  OperationalAlertType.refundRequest => DashboardRoutes.payments,
  OperationalAlertType.tripCancelled => DashboardRoutes.trips,
  OperationalAlertType.general => null,
};
