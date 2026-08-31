import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/business_attention.dart';
import 'overview_kit.dart';

/// The owner's to-do list, full width and directly under the KPI band — the
/// position and the shape الرئيسية gives «يحتاج إلى إجراء».
///
/// A grid rather than a stacked list, for the reason Home documents: a
/// full-width row leaves a hand's width of blank paper between a two-word body
/// and its count, and three short records per row is what a page this wide can
/// actually be read at.
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
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: items.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.allClear,
              title: 'كل شيء تحت السيطرة',
              message: 'لا يوجد ما يحتاج قراراً منك الآن.',
            )
          : OverviewTileGrid(
              children: [
                for (final item in items)
                  _AttentionTile(item: item, onOpenModule: onOpenModule),
              ],
            ),
    );
  }
}

/// One queue: an icon square carrying the only colour on the tile, the title
/// and what clearing it means, then the count and a forward chevron.
///
/// The EWT redesign's colour budget rule, which الرئيسية's queue tile already
/// follows: a tinted glyph reads as a category mark, while a whole tile tinted
/// by severity turns six ordinary queues into six alert boxes shouting at once.
/// The previous revision here tinted the fill.
///
/// None of these is dismissible: dismissing does not refund a passenger or
/// assign a driver, and a list that can be cleared without doing the work stops
/// being a to-do list within a week. An empty section therefore means the
/// console genuinely has nothing to escalate.
class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item, required this.onOpenModule});

  final BusinessAttentionItem item;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(item.kind);
    final title = item.subject == null
        ? spec.title
        : '${spec.title}: ${item.subject}';

    return OverviewRecordTile(
      icon: spec.icon,
      title: title,
      subtitle: spec.action,
      tone: switch (item.kind.severity) {
        BusinessAttentionSeverity.urgent => AppStatusTone.error,
        BusinessAttentionSeverity.warning => AppStatusTone.warning,
        BusinessAttentionSeverity.info => AppStatusTone.info,
      },
      value: item.note ?? '${item.count}',
      onTap: () => onOpenModule(spec.route),
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
