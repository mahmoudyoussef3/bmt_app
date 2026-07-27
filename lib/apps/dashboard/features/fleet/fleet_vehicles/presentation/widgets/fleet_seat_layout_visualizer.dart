import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Draws a vehicle's cabin from the blueprint its **type** resolves to — the
/// same blueprint the Client App renders the rider's seat map from, so what the
/// operator approves here is what the rider sees.
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

    final passengers = seatConfig.seats
        .where((s) => s.seatType == 'passenger')
        .toList()
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
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(50)),
              ),
              child: Column(
                children: [
                  _CabinBanner(
                    label: 'مقدمة الحافلة (التابلوه)',
                    color: scheme.primaryContainer.withAlpha(100),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  // The cabin is a physical object, not a block of text. Column 1
                  // of a blueprint is the driver's side of a left-hand-drive
                  // vehicle, and under the dashboard's global RTL a plain Row
                  // would flip it to the right — putting the steering wheel on
                  // the wrong side and every window seat on the wrong wall. The
                  // grid is pinned to LTR; the Arabic labels around it are not.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        for (final row in blueprint.rows)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.small,
                            ),
                            child: Row(
                              children: [
                                for (final slot in row)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _SlotTile(
                                        slot: slot,
                                        label: slot.isSeat
                                            ? _labelFor(
                                                passengers,
                                                slot.seatNumber,
                                              )
                                            : slot.label,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  _CabinBanner(
                    label: 'مؤخرة الحافلة',
                    color: scheme.surfaceContainerHighest.withAlpha(120),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The seat's real stored label, so the preview shows the numbers that will
  /// end up on `trip_seats` rather than a redrawn sequence.
  String _labelFor(List<SeatLayoutItem> passengers, int seatNumber) {
    final index = seatNumber - 1;
    if (index < 0 || index >= passengers.length) return '$seatNumber';
    return passengers[index].seatNumber;
  }
}

class _CabinBanner extends StatelessWidget {
  const _CabinBanner({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.label});

  final SeatSlot slot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (slot.isGap) return const SizedBox(height: 46);

    final (background, foreground, border, icon) = switch (slot.kind) {
      SeatSlotKind.driver => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        scheme.secondary,
        Icons.settings_accessibility_rounded,
      ),
      SeatSlotKind.door => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        scheme.tertiary,
        Icons.sensor_door_outlined,
      ),
      _ => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary,
        Icons.event_seat_rounded,
      ),
    };

    return Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: foreground),
          if (label.isNotEmpty || slot.kind == SeatSlotKind.door) ...[
            const SizedBox(height: 2),
            Text(
              slot.kind == SeatSlotKind.door && label.isEmpty ? 'باب' : label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
