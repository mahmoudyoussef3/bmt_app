import 'package:flutter/material.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_status_badge.dart';

/// The passenger's name, seat, route and pickup time — everything on the card
/// that is information rather than action.
class PassengerCardDetails extends StatelessWidget {
  const PassengerCardDetails({super.key, required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                passenger.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            PassengerStatusBadge(status: passenger.status),
          ],
        ),
        const SizedBox(height: 4),
        _MutedText('مقعد ${passenger.seat}  •  ${passenger.pickupPoint}'),
        if (passenger.destination.isNotEmpty) ...[
          const SizedBox(height: 8),
          _IconLine(
            icon: Icons.arrow_forward_rounded,
            text: passenger.destination,
          ),
        ],
        if (passenger.pickupTime.isNotEmpty) ...[
          const SizedBox(height: 8),
          _IconLine(
            icon: Icons.schedule_rounded,
            text: passenger.pickupTime,
            color: Colors.blue,
          ),
        ],
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A small icon-led line. Defaults to the muted treatment; a colour promotes it
/// (the pickup time is the one the captain scans for).
class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? Theme.of(context).colorScheme.onSurface.withAlpha(170);

    return Row(
      children: [
        Icon(icon, size: 14, color: resolved),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: resolved,
              fontWeight: color == null ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
