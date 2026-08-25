import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/widgets/booking_status_chips.dart'
    show paymentStatusStyle;
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The last few bookings to come in — the office's sales pulse.
///
/// [DashboardHomeSummary.recentBookings] was computed and never rendered, so
/// the console's landing page could tell an operator how many bookings today
/// held but not a single thing about *who* was buying, on which route, or
/// whether the money for it had cleared. That last part is what makes this an
/// operational panel rather than a nice-to-have: a booking sitting on «تم
/// الرفع» is a receipt somebody has to look at, and seeing it land here is
/// faster than waiting for it to surface in a queue count.
///
/// Ordered newest-first from the same `created_at desc` the Bookings module
/// reads, so this is genuinely "the last N that came in" and not a sample.
class RecentBookingsSection extends StatelessWidget {
  const RecentBookingsSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
    this.maxRows = 6,
    this.now,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;
  final int maxRows;

  /// Injectable clock for each row's age label.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final bookings = summary.recentBookings(limit: maxRows);

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeRecentBookings,
      icon: DashboardIcons.bookingsActive,
      title: 'آخر الحجوزات',
      subtitle: bookings.isEmpty ? null : 'أحدث ما وصل، الأجدّ أولاً',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.bookings),
        child: const Text('كل الحجوزات'),
      ),
      child: bookings.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.bookings,
              title: 'لا حجوزات بعد',
              message: 'يظهر هنا أول حجز فور وصوله من التطبيق أو المكتب.',
            )
          : Column(
              children: [
                for (final booking in bookings) ...[
                  _BookingRow(
                    booking: booking,
                    onOpen: () => onOpenModule(DashboardRoutes.bookings),
                    now: now,
                  ),
                  if (booking != bookings.last)
                    const Divider(height: AppSpacing.medium),
                ],
              ],
            ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onOpen, this.now});

  final OperationBooking booking;
  final VoidCallback onOpen;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = paymentStatusStyle(booking.paymentStatus).tone;
    final style = DashboardColors.status(context, tone);
    final radius = BorderRadius.circular(8);
    final passenger = booking.passengerName.trim().isEmpty
        ? 'راكب بدون اسم'
        : booking.passengerName.trim();

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      passenger,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.route.trim().isEmpty
                          ? 'بدون مسار'
                          : booking.route.trim(),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${booking.paymentAmount.toStringAsFixed(0)} ج.م',
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ageLabel(booking.createdAt, now ?? DateTime.now()),
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.faintInk(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.medium),
              SizedBox(
                width: 84,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DashboardStatusChip(
                    label: booking.paymentStatus.label,
                    color: style.tint,
                    textColor: style.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How long ago the booking landed, at the coarsest unit that still says
/// something. A booking older than a day is not "recent" in any useful sense,
/// so the scale tops out at days rather than reaching for a date.
String _ageLabel(DateTime createdAt, DateTime now) {
  final diff = now.difference(createdAt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  return 'منذ ${diff.inDays} ي';
}
