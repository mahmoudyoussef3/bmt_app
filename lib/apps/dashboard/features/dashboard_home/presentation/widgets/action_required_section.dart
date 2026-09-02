import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/widgets/alert_icon_resolver.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (queues.isNotEmpty)
                      _PanelGrid(
                        rowHeight: 72,
                        children: [
                          for (final item in queues)
                            _QueueTile(item: item, onOpenModule: onOpenModule),
                        ],
                      ),
                    if (queues.isNotEmpty && alerts.isNotEmpty) ...[
                      const Divider(height: AppSpacing.large),
                      _SubHeading(label: 'مستجدات', count: alerts.length),
                      const SizedBox(height: AppSpacing.small),
                    ],
                    if (alerts.isNotEmpty)
                      _PanelGrid(
                        rowHeight: 56,
                        // Two columns, not the queues' three: an alert carries
                        // a sentence of body text where a queue carries a
                        // count, and a third of this panel is not enough width
                        // to say anything before eliding.
                        maxColumns: 2,
                        children: [
                          for (final alert in alerts.take(4))
                            _AlertRow(
                              alert: alert,
                              onTap: () {
                                context
                                    .read<OperationalAlertsCubit>()
                                    .markAsRead(alert.id);
                                final route = _routeForAlert(alert.type);
                                if (route != null) onOpenModule(route);
                              },
                              onMarkRead: () => context
                                  .read<OperationalAlertsCubit>()
                                  .markAsRead(alert.id),
                            ),
                        ],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// The panel's column rule, shared by both of its halves.
///
/// This panel is full-page width, and a full-width row is why its two halves
/// used to read so differently: the queue tiles were already a grid, while the
/// alerts underneath were single rows stretched across 1400px, leaving a hand's
/// width of blank paper between a two-word body and its timestamp. Both are
/// short records; both belong in columns. Only how many columns differs, which
/// is the one thing a caller passes.
class _PanelGrid extends StatelessWidget {
  const _PanelGrid({
    required this.children,
    required this.rowHeight,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double rowHeight;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final columns = fitted > maxColumns ? maxColumns : fitted;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.small,
            mainAxisExtent: rowHeight,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// One queue: an icon square carrying the only colour on the tile, the title
/// and what clearing it means, then the count and a forward chevron. The EWT
/// redesign's colour budget rule — a tinted icon reads as a category mark,
/// while a whole tile tinted by severity turned six ordinary queues into six
/// alert boxes shouting at once.
class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item, required this.onOpenModule});

  final HomeAttentionItem item;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = _toneFor(item.kind.severity);
    final style = DashboardColors.status(context, tone);
    final spec = _specFor(item.kind);
    final radius = BorderRadius.circular(10);

    return Material(
      // Nested-tile tone, one step up the surface ladder from the panel it
      // sits in — a queue is an object inside the card, not an outline drawn
      // on it.
      color: DashboardColors.nested(context),
      borderRadius: radius,
      child: InkWell(
        onTap: () => onOpenModule(spec.route),
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DashboardColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardColors.statusLine(context, tone),
                  ),
                ),
                child: Icon(spec.icon, size: 18, color: style.ink),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      spec.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.action,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.count}',
                style: text.titleMedium?.copyWith(
                  color: style.ink,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Icon(
                DashboardIcons.openModule,
                size: 18,
                color: DashboardColors.faintInk(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label for a run of rows inside a panel that already has a title —
/// «مستجدات» over the event feed, so the operator can tell at a glance which
/// half of the panel is a standing queue and which half is news.
class _SubHeading extends StatelessWidget {
  const _SubHeading({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          label,
          style: text.labelMedium?.copyWith(
            color: DashboardColors.mutedInk(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: text.labelSmall?.copyWith(
            color: DashboardColors.faintInk(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// One unread event, at the density of the queue tiles above it.
///
/// Not the notifications module's [AlertTile]: that row is built for a
/// full-page inbox — 16px padding around a 44px circular glyph and a two-line
/// body — and four of them turned Home's attention panel into a column half a
/// screen tall for news that is one click from the bell anyway. This is the
/// same content at the panel's own rhythm: a 28px glyph square matching
/// `_QueueTile`, one line of title, one of body, the age, and a way to dismiss
/// it without leaving the page.
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.onTap,
    required this.onMarkRead,
  });

  final OperationalAlert alert;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (tone, icon) = AlertIconResolver.resolve(alert.type);
    final style = DashboardColors.status(context, tone);
    final radius = BorderRadius.circular(8);

    return Material(
      color: DashboardColors.nested(context),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.small,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DashboardColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: DashboardColors.statusLine(context, tone),
                  ),
                ),
                child: Icon(icon, size: 15, color: style.ink),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (alert.body.trim().isNotEmpty)
                      Text(
                        alert.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                _ageLabel(alert.createdAt),
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.faintInk(context),
                ),
              ),
              IconButton(
                onPressed: onMarkRead,
                icon: const Icon(DashboardIcons.allClear, size: 16),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                color: DashboardColors.faintInk(context),
                tooltip: 'تعليم كمقروء',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "منذ ٤٠ د" / "منذ ٣ س" / "منذ يومين" — the coarsest unit that still says
/// something. An operational alert older than a week is not news, so the scale
/// stops at days.
String _ageLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  return 'منذ ${diff.inDays} ي';
}

AppStatusTone _toneFor(HomeAttentionSeverity severity) => switch (severity) {
  HomeAttentionSeverity.urgent => AppStatusTone.error,
  HomeAttentionSeverity.warning => AppStatusTone.warning,
  HomeAttentionSeverity.info => AppStatusTone.info,
};

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
