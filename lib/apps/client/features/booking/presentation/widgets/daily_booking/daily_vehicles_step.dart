import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/daily_booking_data.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Step 4 of the daily booking wizard: the available vehicles plus a summary
/// of the selected pickup, destination and time.
class DailyVehiclesStep extends StatelessWidget {
  const DailyVehiclesStep({
    super.key,
    required this.data,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.controller,
    required this.onBook,
  });

  final DailyBookingData data;
  final String pickup;
  final String destination;
  final String time;
  final ScrollController controller;
  final ValueChanged<DailyBookingVehicle> onBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const _AvailableVehiclesHeader(),
        const SizedBox(height: 14),
        for (final vehicle in data.vehicles) ...[
          VehicleCard(
            id: vehicle.id,
            driver: vehicle.driver,
            time: vehicle.time,
            seatsLeft: vehicle.seatsLeft,
            occupancy: vehicle.occupancy,
            onBook: () => onBook(vehicle),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        BookingSummaryCard(
          pickup: pickup,
          destination: destination,
          time: time,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AvailableVehiclesHeader extends StatelessWidget {
  const _AvailableVehiclesHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withAlpha(30),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.booking_availableVehicles,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.booking_pickBestShuttle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
