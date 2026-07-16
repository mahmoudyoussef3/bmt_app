import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/trip_history_item.dart';
import 'trip_history_chip.dart';

/// One completed trip in the history list.
class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({super.key, required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: EdgeInsets.zero,
      onTap: () => context.openTripHistoryDetail(trip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(route: trip.route),
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            child: Column(
              children: [
                _DateRow(trip: trip),
                const SizedBox(height: CaptainDesignTokens.s8),
                _StatsRow(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.success.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: CaptainColors.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: CaptainColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              route,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const _CompletedTag(),
        ],
      ),
    );
  }
}

class _CompletedTag extends StatelessWidget {
  const _CompletedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.success.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br8,
        border: Border.all(
          color: CaptainColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        'مكتملة',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: CaptainColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onVariant = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: onVariant),
        const SizedBox(width: CaptainDesignTokens.s4),
        Expanded(
          child: Text(
            CaptainFormats.fullDate(trip.tripDate),
            style: theme.textTheme.bodySmall?.copyWith(color: onVariant),
          ),
        ),
        Text(
          '${CaptainFormats.clock(trip.departureTime)} → '
          '${CaptainFormats.clock(trip.arrivalTime)}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        TripHistoryChip(
          icon: Icons.people_alt_rounded,
          label: '${trip.boardedCount}/${trip.passengerCount} راكب',
          color: trip.boardingRate >= 1
              ? CaptainColors.success
              : CaptainColors.warning,
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        TripHistoryChip(
          icon: Icons.timer_rounded,
          label: CaptainFormats.duration(trip.duration),
          color: Colors.teal,
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        if (trip.vehicleNumber.isNotEmpty)
          TripHistoryChip(
            icon: Icons.directions_bus_rounded,
            label: trip.vehicleNumber,
            color: onVariant,
          ),
        const Spacer(),
        Icon(Icons.chevron_left_rounded, size: 20, color: onVariant),
      ],
    );
  }
}
