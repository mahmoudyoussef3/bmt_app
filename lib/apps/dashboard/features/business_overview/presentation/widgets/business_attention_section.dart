import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/business_attention.dart';

/// Section 8 — the owner's to-do list.
///
/// Every row is a real queue with a real count, and none of them is
/// dismissible: dismissing does not refund a passenger or assign a driver, and
/// a list that can be cleared without doing the work stops being a to-do list
/// within a week. An empty section therefore means the console genuinely has
/// nothing to escalate.
class BusinessAttentionSection extends StatelessWidget {
  const BusinessAttentionSection({
    super.key,
    required this.items,
    required this.onOpenModule,
  });

  final List<BusinessAttentionItem> items;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final urgent = items
        .where((i) => i.kind.severity == BusinessAttentionSeverity.urgent)
        .length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessAttention,
      icon: items.isEmpty ? DashboardIcons.allClear : DashboardIcons.attention,
      title: 'يحتاج قراراً منك',
      subtitle: items.isEmpty
          ? null
          : '${items.length} بند بانتظارك'
                '${urgent > 0 ? ' · $urgent عاجل' : ''}',
      collapsedSummary: Text(
        items.isEmpty ? 'لا شيء بانتظارك' : _specFor(items.first.kind).title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: items.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.allClear,
              title: 'كل شيء تحت السيطرة',
              message: 'لا يوجد ما يحتاج قراراً منك الآن.',
            )
          : Column(
              children: [
                for (final item in items)
                  _AttentionRow(item: item, onOpenModule: onOpenModule),
              ],
            ),
    );
  }
}

/// One queue: what it is, what clearing it means, how many, and one tap to the
/// screen that clears it. The whole row is the target — an icon-sized button at
/// the end of a row is a miss waiting to happen.
class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item, required this.onOpenModule});

  final BusinessAttentionItem item;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = DashboardChartPalette.of(context);
    final tone = switch (item.kind.severity) {
      BusinessAttentionSeverity.urgent => palette.negative,
      BusinessAttentionSeverity.warning => palette.warning,
      BusinessAttentionSeverity.info => palette.active,
    };
    final spec = _specFor(item.kind);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final title = item.subject == null
        ? spec.title
        : '${spec.title}: ${item.subject}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: () => onOpenModule(spec.route),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.small),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: radius,
                  ),
                  child: Icon(spec.icon, size: 18, color: tone),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        spec.action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.note ?? '${item.count}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  DashboardIcons.openModule,
                  size: 18,
                  color: scheme.onSurfaceVariant,
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

_QueueSpec _specFor(BusinessAttentionKind kind) => switch (kind) {
  BusinessAttentionKind.paymentsAwaitingReview => const _QueueSpec(
    title: 'إيصالات بانتظار المراجعة',
    action: 'راجع الإيصال واقبله أو ارفضه',
    route: DashboardRoutes.paymentVerification,
    icon: DashboardIcons.paymentReview,
  ),
  BusinessAttentionKind.refundRequests => const _QueueSpec(
    title: 'طلبات استرداد بانتظار قرارك',
    action: 'اعتمد المبلغ أو ارفض الطلب',
    route: DashboardRoutes.wallet,
    icon: DashboardIcons.wallet,
  ),
  BusinessAttentionKind.tripsWithoutCaptain => const _QueueSpec(
    title: 'رحلات بدون سائق',
    action: 'عيّن سائقاً قبل موعد القيام',
    route: DashboardRoutes.trips,
    icon: DashboardIcons.captain,
  ),
  BusinessAttentionKind.bookingConflicts => const _QueueSpec(
    title: 'حجوزات على رحلات ملغاة',
    action: 'ألغِ الحجز أو انقل الراكب لرحلة أخرى',
    route: DashboardRoutes.bookings,
    icon: DashboardIcons.bookings,
  ),
  BusinessAttentionKind.staleTrips => const _QueueSpec(
    title: 'رحلات فات موعدها ومازالت مفتوحة',
    action: 'أغلقها أو ألغِها لتصحيح الأرقام',
    route: DashboardRoutes.trips,
    icon: DashboardIcons.time,
  ),
  BusinessAttentionKind.highCancellationRate => const _QueueSpec(
    title: 'معدل الإلغاء تجاوز الحد',
    action: 'راجع أسباب الإلغاء في الحجوزات',
    route: DashboardRoutes.bookings,
    icon: DashboardIcons.attention,
  ),
  BusinessAttentionKind.vehiclesInMaintenance => const _QueueSpec(
    title: 'مركبات في الصيانة',
    action: 'تابع موعد عودتها للخدمة',
    route: DashboardRoutes.vehicles,
    icon: DashboardIcons.vehicle,
  ),
  BusinessAttentionKind.expiringDocuments => const _QueueSpec(
    title: 'مستندات أسطول تحتاج متابعة',
    action: 'جدّد المستندات قبل انتهائها',
    route: DashboardRoutes.fleet,
    icon: DashboardIcons.document,
  ),
  BusinessAttentionKind.urgentComplaints => const _QueueSpec(
    title: 'شكاوى عاجلة مفتوحة',
    action: 'رد على العميل اليوم',
    route: DashboardRoutes.tickets,
    icon: DashboardIcons.tickets,
  ),
  BusinessAttentionKind.licenseLimit => const _QueueSpec(
    title: 'اقتربت من حد الباقة',
    action: 'راجع باقتك قبل أن تتوقف الإضافة',
    route: DashboardRoutes.officeBilling,
    icon: DashboardIcons.licenses,
  ),
  BusinessAttentionKind.captainRequests => const _QueueSpec(
    title: 'طلبات انضمام سائقين',
    action: 'اقبل الطلب أو ارفضه',
    route: DashboardRoutes.captainRequests,
    icon: DashboardIcons.captainRequests,
  ),
  BusinessAttentionKind.subscriptionsAwaitingPayment => const _QueueSpec(
    title: 'اشتراكات بانتظار الدفع',
    action: 'تابع تحصيل قيمة الباقة',
    route: DashboardRoutes.subscriptions,
    icon: DashboardIcons.subscriptions,
  ),
};
