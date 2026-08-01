import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class VehicleCard extends StatelessWidget {
  final String id;
  final String driver;
  final String time;
  final int seatsLeft;
  final double occupancy;
  final VoidCallback onBook;

  const VehicleCard({
    super.key,
    required this.id,
    required this.driver,
    required this.time,
    required this.seatsLeft,
    required this.occupancy,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFull = seatsLeft <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.tracking_vehicle} $id',
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    driver,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isFull
                      ? ClientColors.journeyRedLightFor(context)
                      : ClientColors.journeyCyanLightFor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isFull ? l10n.booking_full : l10n.booking_available,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: isFull
                        ? ClientColors.onJourneyRedFor(context)
                        : ClientColors.onJourneyCyanFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 6),
              Text(time, style: ClientTypography.bodySmall(context)),
              const SizedBox(width: 14),
              Icon(
                Icons.event_seat_rounded,
                size: 16,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$seatsLeft ${l10n.seatSelection_seatsLeftLabel}',
                style: ClientTypography.bodySmall(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.booking_occupancy,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: occupancy.clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: ClientColors.surfaceMutedFor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ClientColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: ClientColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.booking_selectSeat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
