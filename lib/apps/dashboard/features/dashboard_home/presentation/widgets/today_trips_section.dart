import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Today's departures, in the order they leave.
///
/// The home screen used to list "upcoming trips" — soonest first across every
/// future day — which quietly answered a different question: an operator
/// opening the console at 7am wants the board for *today*, not a trip next
/// Thursday sitting above the 8am that is still missing its driver. Trips
/// further out have a module of their own.
class TodayTripsSection extends StatelessWidget {
  const TodayTripsSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
    this.onCreateTrip,
    this.maxRows = 6,
    this.now,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;
  final VoidCallback? onCreateTrip;
  final int maxRows;

  /// Injectable clock for each row's relative-time label.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final trips = summary.todayTripsByDeparture;
    final shown = trips.take(maxRows).toList();
    final hidden = trips.length - shown.length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeTodayTrips,
      icon: DashboardIcons.tripsActive,
      title: 'رحلات اليوم',
      subtitle: trips.isEmpty ? null : 'مرتبة حسب موعد القيام',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.trips),
        child: const Text('كل الرحلات'),
      ),
      child: trips.isEmpty
          ? DashboardEmptyState(
              icon: DashboardIcons.trips,
              title: 'لا رحلات اليوم',
              message: 'لم تُجدول أي رحلة لهذا اليوم بعد.',
              action: onCreateTrip == null
                  ? null
                  : FilledButton.tonalIcon(
                      onPressed: onCreateTrip,
                      icon: const Icon(DashboardIcons.add, size: 18),
                      label: const Text('إنشاء رحلة'),
                    ),
            )
          : Column(
              children: [
                for (final trip in shown) ...[
                  _TripRow(
                    trip: trip,
                    onOpen: () => onOpenModule(DashboardRoutes.trips),
                    now: now,
                  ),
                  if (trip != shown.last)
                    const Divider(height: AppSpacing.medium),
                ],
                if (hidden > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: TextButton(
                      onPressed: () => onOpenModule(DashboardRoutes.trips),
                      child: Text('و $hidden رحلة أخرى اليوم'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onOpen, this.now});

  final OperationTrip trip;
  final VoidCallback onOpen;

  /// Injectable clock for the relative-time label, so tests don't race a real
  /// departure against the wall clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);
    final occupancy = trip.capacity == 0
        ? 0.0
        : trip.bookedSeats / trip.capacity;
    final (statusColor, statusBg) = _statusColors(trip.status, scheme, palette);
    final noCaptain = trip.driver.trim().isEmpty;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final relative = _relativeLabel(trip.scheduledAt, now ?? DateTime.now());

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.departure.isEmpty ? '--:--' : trip.departure,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (relative != null)
                      Text(
                        relative,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.faintInk(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              SizedBox(
                width: 1,
                height: 34,
                child: ColoredBox(color: DashboardColors.divider(context)),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.route.isEmpty ? 'رحلة بدون مسار' : trip.route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.medium,
                      runSpacing: 2,
                      children: [
                        _MetaChip(
                          icon: DashboardIcons.captain,
                          label: noCaptain ? 'بدون سائق' : trip.driver,
                          tone: noCaptain ? palette.negative : null,
                        ),
                        _MetaChip(
                          icon: DashboardIcons.vehicle,
                          label: trip.vehicle.isEmpty
                              ? 'بدون مركبة'
                              : trip.vehicle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              SizedBox(
                width: 92,
                child: Row(
                  children: [
                    Expanded(child: AppProgressBar(progress: occupancy)),
                    const SizedBox(width: AppSpacing.xSmall),
                    Text(
                      '${trip.bookedSeats}/${trip.capacity}',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              DashboardStatusChip(
                label: trip.status.label,
                color: statusBg,
                textColor: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(
    OperationTripStatus status,
    ColorScheme scheme,
    DashboardChartPalette palette,
  ) {
    return switch (status) {
      OperationTripStatus.inProgress || OperationTripStatus.boarding => (
        palette.positive,
        palette.positive.withAlpha(26),
      ),
      OperationTripStatus.completed => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      OperationTripStatus.cancelled => (
        palette.negative,
        palette.negative.withAlpha(26),
      ),
      OperationTripStatus.scheduled || OperationTripStatus.openForBooking => (
        palette.active,
        palette.active.withAlpha(26),
      ),
    };
  }
}

/// "بعد ساعة" / "بعد ٩٠ د" / `null` once it has already left — Home only ever
/// shows *today's* board, so this never has to reach for "غداً" or a weekday
/// name.
String? _relativeLabel(DateTime? scheduledAt, DateTime now) {
  if (scheduledAt == null) return null;
  final diff = scheduledAt.difference(now);
  if (diff.inMinutes <= 0) return null;
  if (diff.inMinutes < 60) return 'بعد ${diff.inMinutes} د';
  final hours = (diff.inMinutes / 60).round();
  if (hours <= 1) return 'بعد ساعة';
  if (hours == 2) return 'بعد ساعتين';
  // 'بعد ٣ ساعات' spelled out does not fit the departure column and elided to
  // 'بعد ٣ ساع…', which reads as a typo rather than as three hours. The short
  // unit is the same one the booking and alert ages use, so the whole page
  // says "س" for an hour.
  return 'بعد $hours س';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tone ?? scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: tone == null ? null : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
