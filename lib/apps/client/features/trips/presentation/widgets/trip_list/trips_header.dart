import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trip_stat_chip.dart';

/// The Trips tab's gradient hero: title, subtitle, "book a trip" action, and
/// upcoming/active stat chips. Uses [ClientColors.heroGradientFor] — the same
/// treatment as Home and Routes Hub — so all three read as one BMT identity.
class TripsHeader extends StatelessWidget {
  const TripsHeader({
    super.key,
    required this.upcomingCount,
    required this.activeCount,
    required this.onBookTrip,
  });

  final int upcomingCount;
  final int activeCount;
  final VoidCallback onBookTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        boxShadow: ClientElevation.md(context),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Trips',
                      style: ClientTypography.headingLarge(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upcoming, active, and past commutes',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: Colors.white.withAlpha(205)),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onBookTrip,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                tooltip: 'Book new trip',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TripStatChip(
                  label: 'Upcoming',
                  value: '$upcomingCount',
                  icon: Icons.upcoming_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TripStatChip(
                  label: 'Active',
                  value: '$activeCount',
                  icon: Icons.directions_bus_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
