import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_chips.dart';

/// Trip Details' hero: status, reference, route line, and quick facts
/// (date, time, seats).
class TripHeroCard extends StatelessWidget {
  const TripHeroCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [ClientColors.primary, Color(0xFF0D4FC4)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(55),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -36,
            end: -26,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 150,
              color: Colors.white.withAlpha(30),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HeroStatusChip(
                    label: trip.statusLabel,
                    color: _statusColor(trip.status),
                  ),
                  const Spacer(),
                  Text(
                    trip.reference,
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: Colors.white.withAlpha(220),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                trip.routeLine,
                style: ClientTypography.headingLarge(
                  context,
                ).copyWith(color: Colors.white, height: 1.25),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  HeroMetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: trip.dateLabel,
                  ),
                  HeroMetaChip(
                    icon: Icons.access_time_rounded,
                    label: trip.timeLabel,
                  ),
                  HeroMetaChip(
                    icon: Icons.event_seat_rounded,
                    label: _seatsLabel(trip),
                  ),
                ],
              ),
              if (trip.completedAt != null) ...[
                const SizedBox(height: 14),
                HeroMetaChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Completed ${trip.completedAt}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TripStatus status) {
    return switch (status) {
      TripStatus.upcoming => ClientColors.primaryLight,
      TripStatus.inProgress => ClientColors.journeyGreenLight,
      TripStatus.completed => ClientColors.journeySlateLight,
      TripStatus.cancelled => ClientColors.journeyRedLight,
    };
  }

  String _seatsLabel(TripData trip) {
    if (trip.seats.isEmpty) return 'No seat selected';
    if (trip.seats.length == 1) return 'Seat ${trip.seats.first}';
    return '${trip.seats.length} seats';
  }
}
