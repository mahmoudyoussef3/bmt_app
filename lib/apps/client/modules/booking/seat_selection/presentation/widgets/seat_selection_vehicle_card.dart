import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: ClientColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        vehicleType,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vehicleName,
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      vehicleModel,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$availableSeats',
                    style: ClientTypography.headingLarge(
                      context,
                    ).copyWith(color: ClientColors.primary),
                  ),
                  Text(
                    'seats left',
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: ClientColors.borderFor(context)),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: ClientColors.primaryLight,
                child: Text(
                  driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: ClientColors.journeyAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driverRating.toStringAsFixed(1),
                          style: ClientTypography.bodySmall(
                            context,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          ' · Captain',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ClientColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
