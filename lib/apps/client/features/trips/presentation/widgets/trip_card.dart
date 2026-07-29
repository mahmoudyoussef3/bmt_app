import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_driver_row.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trip_card_attention_strip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_route_marks.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// A trip list card: status (with a live-pulse dot when in progress — never
/// color alone, spec FR-018), route, schedule, driver, and payment status.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final TripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientStatusBadge(
                status: journeyStatusFor(trip.status),
                label: statusLabelFor(context, trip.status),
                showDot: trip.status == TripStatus.inProgress,
              ),
              const Spacer(),
              Text(
                trip.fare,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripRouteMarks(
                pickupColor: scheme.tertiary,
                dropoffColor: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickupLabelFor(context, trip),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      destinationLabelFor(context, trip),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DirectionalIcon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: scheme.outline.withAlpha(90)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip.dateLabel} · ${trip.timeLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Who ran this trip — the office the rider actually booked with.
              if (trip.officeName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.storefront_rounded,
                  size: 13,
                  color: scheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trip.officeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TripDriverRow(trip: trip),
          TripCardAttentionStrip(trip: trip),
        ],
      ),
    );
  }
}
