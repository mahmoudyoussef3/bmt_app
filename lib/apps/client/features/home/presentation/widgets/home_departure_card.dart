import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';

/// A single trip in the "Departing soon" carousel: time, live boarding
/// signal, endpoints and seat scarcity at a glance.
class HomeDepartureCard extends StatelessWidget {
  const HomeDepartureCard({
    super.key,
    required this.trip,
    required this.width,
    required this.onTap,
  });

  final NearbyTripData trip;
  final double width;
  final VoidCallback onTap;

  /// Cross-axis size for the horizontal ListView parent.
  static const double listHeight = 168;

  @override
  Widget build(BuildContext context) {
    final scarceSeats = trip.seatsLeft <= 5;
    final seatColor = scarceSeats
        ? ClientColors.journeyAmber
        : ClientColors.journeyGreen;

    return SizedBox(
      width: width,
      child: PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.lg),
            border: Border.all(color: ClientColors.borderFor(context)),
            boxShadow: ClientElevation.sm(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Chip(
                    color: ClientColors.primaryFor(context),
                    icon: Icons.schedule_rounded,
                    label: trip.departureTime,
                  ),
                  const Spacer(),
                  if (trip.isLive)
                    Row(
                      children: [
                        const PulseDot(
                          color: ClientColors.journeyGreen,
                          size: 7,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Boarding',
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: ClientColors.journeyGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: ClientColors.textTertiaryFor(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _Chip(
                    color: seatColor,
                    icon: Icons.event_seat_rounded,
                    label: scarceSeats
                        ? 'Only ${trip.seatsLeft.clamp(0, 999)} left'
                        : '${trip.seatsLeft.clamp(0, 999)} seats',
                  ),
                  const Spacer(),
                  Text(
                    'Book now',
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: ClientColors.primaryFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: ClientColors.primaryFor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
