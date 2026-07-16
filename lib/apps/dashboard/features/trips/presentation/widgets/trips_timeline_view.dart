import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import 'trip_row_card.dart';
import 'trip_ui_helpers.dart';

/// Chronological, date-grouped rendering of [trips] (already sorted by
/// [OperationTrip.scheduledAt]) with a connecting rail per day.
class TripsTimelineView extends StatelessWidget {
  const TripsTimelineView({
    super.key,
    required this.trips,
    required this.onOpenDetails,
  });

  final List<OperationTrip> trips;
  final void Function(OperationTrip trip) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Center(child: Text('لا توجد رحلات مطابقة للبحث الحالي.')),
      );
    }
    final groups = <String, List<OperationTrip>>{};
    for (final trip in trips) {
      groups.putIfAbsent(trip.date, () => []).add(trip);
    }
    final dates = groups.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dates.indexed.map((entry) {
        final date = entry.$2;
        return Padding(
          padding: EdgeInsets.only(
            top: entry.$1 == 0 ? 0 : AppSpacing.large,
          ),
          child: _TimelineDayGroup(
            date: date,
            trips: groups[date]!,
            onOpenDetails: onOpenDetails,
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineDayGroup extends StatelessWidget {
  const _TimelineDayGroup({
    required this.date,
    required this.trips,
    required this.onOpenDetails,
  });

  final String date;
  final List<OperationTrip> trips;
  final void Function(OperationTrip trip) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                tripFriendlyDate(date),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Text(
                '${trips.length} رحلة',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ...trips.indexed.map((entry) {
          final isLast = entry.$1 == trips.length - 1;
          final trip = entry.$2;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Text(
                        trip.departure.length >= 5
                            ? trip.departure.substring(0, 5)
                            : trip.departure,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tripStatusColor(context, trip.status),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: scheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: TripRowCard(
                      trip: trip,
                      onOpenDetails: () => onOpenDetails(trip),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
