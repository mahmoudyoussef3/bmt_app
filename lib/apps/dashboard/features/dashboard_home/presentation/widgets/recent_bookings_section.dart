import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The last handful of bookings that came in — who booked, on which line, and
/// whether the money arrived.
///
/// Replaces a panel of four running totals ("confirmed: 812, cancelled: 96").
/// Totals of every booking the office has ever taken do not change between two
/// mornings and cannot be acted on; the newest six can be, and the totals still
/// live one click away in the Bookings module.
class RecentBookingsSection extends StatelessWidget {
  const RecentBookingsSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
    this.limit = 6,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final bookings = summary.recentBookings(limit: limit);

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeRecentBookings,
      icon: DashboardIcons.bookingsActive,
      title: 'أحدث الحجوزات',
      subtitle: bookings.isEmpty ? null : 'آخر ما وصل من العملاء',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.bookings),
        child: const Text('كل الحجوزات'),
      ),
      child: bookings.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.bookings,
              title: 'لا حجوزات بعد',
              message: 'ستظهر هنا الحجوزات الجديدة فور وصولها.',
            )
          : Column(
              children: [
                for (final booking in bookings)
                  _BookingRow(
                    booking: booking,
                    onOpen: () => onOpenModule(DashboardRoutes.bookings),
                  ),
              ],
            ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onOpen});

  final OperationBooking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final (payColor, payBg) = _paymentColors(booking.paymentStatus, palette);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.small,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.passengerName.trim().isEmpty
                          ? 'راكب غير مسمى'
                          : booking.passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _context(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                booking.amountLabel,
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpacing.small),
              StatusChip(
                label: booking.paymentStatus.label,
                color: payBg,
                textColor: payColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Route + departure time, falling back to whatever of the two exists — a
  /// booking whose trip was deleted still has to render something truthful.
  String _context(OperationBooking booking) {
    final route = booking.route.trim();
    final time = booking.tripTime.trim();
    if (route.isEmpty && time.isEmpty) return booking.bookingNumber;
    if (time.isEmpty) return route;
    if (route.isEmpty) return time;
    return '$route · $time';
  }

  (Color?, Color?) _paymentColors(
    PaymentStatus status,
    DashboardChartPalette palette,
  ) {
    return switch (status) {
      PaymentStatus.approved => (
        palette.positive,
        palette.positive.withAlpha(26),
      ),
      PaymentStatus.rejected ||
      PaymentStatus.failed ||
      PaymentStatus.cancelled => (
        palette.negative,
        palette.negative.withAlpha(26),
      ),
      PaymentStatus.submitted || PaymentStatus.underReview => (
        palette.warning,
        palette.warning.withAlpha(26),
      ),
      
      PaymentStatus.pending || PaymentStatus.refunded => (null, null),
    };
  }
}
