import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// Draws a vehicle's cabin from the blueprint its **type** resolves to, through
/// the shared seat renderer — so what the operator approves here is, to the
/// pixel, the cabin the rider will see and the one the seats tab will manage.
class FleetSeatLayoutVisualizer extends StatelessWidget {
  final SeatConfiguration seatConfig;
  final VehicleType vehicleType;

  const FleetSeatLayoutVisualizer({
    super.key,
    required this.seatConfig,
    required this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    if (seatConfig.seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
        child: Text('لا يوجد تخطيط مقاعد مدخل للمركبة.'),
      );
    }

    final passengers =
        seatConfig.seats.where((s) => s.seatType == 'passenger').toList()
          ..sort((a, b) {
            final byRow = a.row.compareTo(b.row);
            return byRow != 0 ? byRow : a.column.compareTo(b.column);
          });

    final blueprint = VehicleSeatLayouts.resolve(
      type: vehicleType,
      seats: [for (final s in passengers) (row: s.row, column: s.column)],
    );

    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تخطيط المقاعد الداخلي',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '${passengers.length} مقعد راكب • ${blueprint.rows.length} صف',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          // A preview, so every seat reads `available`: this is the shape of
          // the vehicle being saved, not the state of any trip on it.
          VehicleSeatLayout(
            blueprint: blueprint,
            seats: [
              for (final seat in passengers)
                VehicleSeatData(
                  id: seat.seatNumber,
                  // The seat's real stored label, so the preview shows the
                  // numbers that will end up on `trip_seats` rather than a
                  // redrawn sequence.
                  label: seat.seatNumber,
                  state: SeatViewState.available,
                  enabled: false,
                ),
            ],
            density: SeatLayoutDensity.compact,
            maxWidth: 320,
          ),
        ],
      ),
    );
  }
}
