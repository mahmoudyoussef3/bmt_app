import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';

import '../../domain/entities/office_trip.dart';
import 'office_trip_tile.dart';

/// The office's departure board, cut into days.
///
/// The board carries up to a month of departures, and an unbroken column of
/// times is unreadable past the first screen: a rider looking for "tomorrow
/// evening" has to read every tile to find where tomorrow starts. The trips
/// arrive already ordered by date then time, so grouping is a pure presentation
/// fold — no re-sorting, no invented ordering.
class OfficeDeparturesSection extends StatelessWidget {
  const OfficeDeparturesSection({
    super.key,
    required this.trips,
    required this.onOpenTrip,
  });

  final List<OfficeTrip> trips;
  final ValueChanged<OfficeTrip> onOpenTrip;

  /// Consecutive runs sharing a date, in arrival order.
  List<List<OfficeTrip>> get _days {
    final days = <List<OfficeTrip>>[];
    for (final trip in trips) {
      final current = days.isEmpty ? null : days.last;
      if (current != null && current.first.tripDate == trip.tripDate) {
        current.add(trip);
      } else {
        days.add([trip]);
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, day) in days.indexed) ...[
          if (index > 0) const SizedBox(height: ClientSpacing.md),
          _DayHeading(label: formatTripDay(context, day.first.tripDate)),
          for (final trip in day) ...[
            const SizedBox(height: ClientSpacing.xs),
            OfficeTripTile(trip: trip, onTap: () => onOpenTrip(trip)),
          ],
        ],
      ],
    );
  }
}

/// "Today", "Tomorrow", or the date — set in a pill with a rule running out to
/// the edge, so the eye can find where one day's departures end without reading
/// any of them.
class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        top: ClientSpacing.sm,
        bottom: ClientSpacing.xxs,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(ClientRadius.pill),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: ClientColors.primaryFor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: ClientTypography.labelMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              color: ClientColors.borderFor(context).withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
