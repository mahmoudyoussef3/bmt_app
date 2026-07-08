import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';

/// One read-only seat in the Trip Details layout, styled to match the booking
/// seat simulation: the passenger's own seat is highlighted, others are shown
/// as occupied or still-available exactly as the live `trip_seats` data says.
class TripSeatTile extends StatelessWidget {
  const TripSeatTile({super.key, required this.seat, this.size = 44});

  final TripSeat seat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _palette(context);
    final icon = switch (seat.state) {
      TripSeatState.mine => Icons.person_rounded,
      TripSeatState.occupied => Icons.person_outline_rounded,
      TripSeatState.available => Icons.event_seat_rounded,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: border == null ? null : Border.all(color: border, width: 1.4),
        boxShadow: seat.isMine ? ClientElevation.sm(context) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size * 0.36, color: fg),
          const SizedBox(height: 2),
          Text(
            seat.displayLabel,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: fg, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color?) _palette(BuildContext context) {
    return switch (seat.state) {
      TripSeatState.mine => (
        ClientColors.primary,
        Colors.white,
        ClientColors.primary,
      ),
      TripSeatState.occupied => (
        ClientColors.surfaceMutedFor(context),
        ClientColors.textTertiaryFor(context),
        ClientColors.borderFor(context),
      ),
      TripSeatState.available => (
        ClientColors.journeyGreenLight,
        ClientColors.journeyGreen,
        ClientColors.journeyGreen.withAlpha(70),
      ),
    };
  }
}
