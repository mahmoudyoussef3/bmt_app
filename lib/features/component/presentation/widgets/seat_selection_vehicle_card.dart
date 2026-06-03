import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Compact vehicle + driver summary for seat selection.
class SeatSelectionVehicleCard extends StatelessWidget {
  const SeatSelectionVehicleCard({
    super.key,
    this.vehicleType = 'Premium Coach',
    this.vehicleName = 'Mega Coach Elite',
    this.vehicleModel = 'Mercedes-Benz Tourismo 2024',
    this.airConditioning = 'Available',
    this.seatType = 'Leather executive',
    this.driverName = 'Ahmed Mohamed',
    this.driverRating = 4.9,
    this.availableSeats = 10,
  });

  final String vehicleType;
  final String vehicleName;
  final String vehicleModel;
  final String airConditioning;
  final String seatType;
  final String driverName;
  final double driverRating;
  final int availableSeats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      radius: 22,
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(60)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withAlpha(80),
                      scheme.secondary.withAlpha(50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_bus_filled_rounded,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(label: vehicleType),
                    const SizedBox(height: 6),
                    Text(
                      vehicleName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vehicleModel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$availableSeats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'seats left',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppSeparator(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.ac_unit_rounded,
                label: 'A/C · $airConditioning',
              ),
              _MetaChip(icon: Icons.chair_rounded, label: seatType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const AppAvatar(initials: 'AM', radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          driverRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' · Captain',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
