import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/passenger.dart';

class PassengerCard extends StatelessWidget {
  const PassengerCard({
    super.key,
    required this.passenger,
    required this.onCall,
    required this.onChat,
  });

  final Passenger passenger;
  final VoidCallback onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(initials: passenger.name.characters.first),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        passenger.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _StatusBadge(status: passenger.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'مقعد ${passenger.seat} • ${passenger.pickupPoint}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (passenger.destination.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '→ ${passenger.destination}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (passenger.pickupTime.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    passenger.pickupTime,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.primary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _ContactButton(
                icon: Icons.call_rounded,
                tooltip: 'اتصال',
                onPressed: onCall,
              ),
              const SizedBox(height: 6),
              _ContactButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'مراسلة',
                onPressed: onChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final PassengerBoardingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PassengerBoardingStatus.boarded => ('صعد', Colors.green),
      PassengerBoardingStatus.pending => ('بانتظار', Colors.orange),
      PassengerBoardingStatus.absent => ('لم يحضر', Colors.red),
      PassengerBoardingStatus.cancelled => ('ملغي', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          fixedSize: const Size(40, 40),
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.primary,
        ),
      ),
    );
  }
}
