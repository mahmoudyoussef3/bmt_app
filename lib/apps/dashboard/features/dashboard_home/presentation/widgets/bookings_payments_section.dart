import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// Bookings and payments side by side — the payments panel deliberately leads
/// with what needs a decision (pending review), not the totals, per the
/// "prioritize what needs attention" requirement.
class BookingsPaymentsSection extends StatelessWidget {
  const BookingsPaymentsSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final bookingsPanel = _bookingsPanel(context);
    final paymentsPanel = _paymentsPanel(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: [
              bookingsPanel,
              const SizedBox(height: AppSpacing.medium),
              paymentsPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: bookingsPanel),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: paymentsPanel),
          ],
        );
      },
    );
  }

  Widget _bookingsPanel(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DashboardPanel(
      icon: Icons.event_seat_rounded,
      title: 'الحجوزات',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.bookings),
        child: const Text('عرض الكل'),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'إجمالي الحجوزات',
            value: summary.bookings.length,
            color: scheme.primary,
          ),
          _StatRow(
            label: 'حجوزات مؤكدة',
            value: summary.bookingCountByStatus(BookingStatus.confirmed),
            color: palette.positive,
          ),
          _StatRow(
            label: 'حجوزات قيد الانتظار',
            value: summary.bookingCountByStatus(BookingStatus.reserved),
            color: palette.warning,
          ),
          _StatRow(
            label: 'حجوزات ملغاة',
            value: summary.bookingCountByStatus(BookingStatus.cancelled),
            color: palette.negative,
          ),
        ],
      ),
    );
  }

  Widget _paymentsPanel(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final pendingReview = summary.pendingPaymentReviewsCount;
    return DashboardPanel(
      icon: Icons.account_balance_wallet_rounded,
      title: 'المدفوعات',
      trailing: pendingReview > 0
          ? FilledButton.tonal(
              onPressed: () =>
                  onOpenModule(DashboardRoutes.paymentVerification),
              child: const Text('مراجعة المدفوعات'),
            )
          : null,
      child: Column(
        children: [
          _StatRow(
            label: 'مدفوعات مكتملة',
            value: summary.paymentCountByStatus(PaymentStatus.approved),
            color: palette.positive,
          ),
          _StatRow(
            label: 'مدفوعات معلقة',
            value:
                summary.paymentCountByStatus(PaymentStatus.pending) +
                summary.paymentCountByStatus(PaymentStatus.submitted) +
                summary.paymentCountByStatus(PaymentStatus.underReview),
            color: palette.warning,
          ),
          _StatRow(
            label: 'مدفوعات مرفوضة',
            value: summary.paymentCountByStatus(PaymentStatus.rejected),
            color: palette.negative,
          ),
          const Divider(height: AppSpacing.large),
          _StatRow(
            label: 'إجمالي المبلغ المحصل',
            valueLabel:
                '${summary.revenue.grandTotalRevenue.toStringAsFixed(0)} ج.م',
            color: palette.active,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.color,
    this.value,
    this.valueLabel,
    this.emphasize = false,
  }) : assert(value != null || valueLabel != null);

  final String label;
  final int? value;
  final String? valueLabel;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            valueLabel ?? '$value',
            style: (emphasize ? text.titleMedium : text.titleSmall)?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
