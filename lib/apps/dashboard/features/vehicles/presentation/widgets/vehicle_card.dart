import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/vehicle.dart';
import 'vehicle_status_badge.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const VehicleCard({required this.vehicle, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.directions_bus_outlined,
                      size: 58,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.small,
                  top: AppSpacing.small,
                  child: VehicleStatusBadge(status: vehicle.status),
                ),
                Positioned(
                  left: AppSpacing.small,
                  bottom: AppSpacing.small,
                  child: Text(
                    vehicle.imageLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            vehicle.plateNumber,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(vehicle.model, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.medium),
          _VehicleFact(icon: Icons.person_outline, text: vehicle.currentDriver),
          const SizedBox(height: AppSpacing.xSmall),
          _VehicleFact(
            icon: Icons.event_seat_outlined,
            text: 'السعة ${vehicle.capacity}',
          ),
          const SizedBox(height: AppSpacing.xSmall),
          _VehicleFact(
            icon: Icons.alt_route_outlined,
            text: vehicle.currentRoute,
          ),
        ],
      ),
    );
  }
}

class _VehicleFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VehicleFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
