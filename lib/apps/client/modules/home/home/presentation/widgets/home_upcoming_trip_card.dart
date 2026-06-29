import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/avatar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

/// Prominent upcoming trip on the home screen.
class HomeUpcomingTripCard extends StatelessWidget {
  const HomeUpcomingTripCard({super.key, required this.onTap, this.onTrack});

  final VoidCallback onTap;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your next trip',
                  style: AppTypography.subheading(scheme),
                ),
              ),
              const StatusChip(label: 'Driver assigned'),
            ],
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.trip_origin_rounded,
                size: 18,
                color: scheme.secondary,
              ),
              const SizedBox(width: AppLayout.spaceSm),
              Expanded(
                child: Text(
                  'Banha Station → Smart Village',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceSm),
          Text(
            'Today, Jun 3 · Departs 8:40 AM',
            style: AppTypography.caption(
              scheme,
            ).copyWith(color: scheme.onSurface.withAlpha(180)),
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Row(
            children: [
              const AppAvatar(initials: 'AM', radius: 18),
              const SizedBox(width: AppLayout.spaceSm),
              Expanded(
                child: Text(
                  'Ahmed Mohamed · ETA pickup 8:32 AM',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onTrack != null)
                TextButton(onPressed: onTrack, child: const Text('Track')),
            ],
          ),
        ],
      ),
    );
  }
}
