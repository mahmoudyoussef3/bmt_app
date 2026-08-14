import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_chips.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_fact_strip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_journey.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_hero_facts.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_hero_glow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_schedule_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';


class TripHeroCard extends StatelessWidget {
  const TripHeroCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final badge = ClientColors.journeyBadgeFor(
      context,
      journeyStatusFor(trip.status),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ClientColors.heroTopFor(context).withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const PositionedDirectional(
              top: -70,
              end: -50,
              child: TripHeroGlow(),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeroStatusChip(
                        label: statusLabelFor(context, trip.status),
                        color: badge.label,
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: HeroReferenceChip(reference: trip.reference),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  HeroJourney(
                    pickup: pickupLabelFor(context, trip),
                    destination: destinationLabelFor(context, trip),
                    departureLabel: tripTimeLabel(context, trip),
                  ),
                  const SizedBox(height: 22),
                  HeroFactStrip(facts: tripHeroFacts(context, trip)),
                  if (trip.completedAt != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.trips_completedAt(trip.completedAt!),
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: Colors.white.withAlpha(200)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
