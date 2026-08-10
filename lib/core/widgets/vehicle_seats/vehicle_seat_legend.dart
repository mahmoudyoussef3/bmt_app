import 'package:flutter/material.dart';

import 'package:bmt_app/core/vehicles/seat_view_state.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_data.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_palette.dart';

/// The key to the seat map's colours.
///
/// Shown only where it earns its place — a booking screen needs it, a compact
/// dashboard card does not — so [VehicleSeatLayout] keeps it off by default and
/// the parent turns it on.
///
/// It lists only the states actually on the map. A legend that explains four
/// states when three are present teaches the rider to distrust it.
class VehicleSeatLegend extends StatelessWidget {
  const VehicleSeatLegend({
    super.key,
    required this.states,
    this.labels = const VehicleSeatLabels(),
    this.palette,
  });

  final List<SeatViewState> states;
  final VehicleSeatLabels labels;
  final VehicleSeatPalette? palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette ?? VehicleSeatPalette.of(context);

    // Fixed order, so the legend does not reshuffle as seats change state
    // underneath the rider.
    final ordered = [
      for (final state in SeatViewState.values)
        if (states.contains(state)) state,
    ];
    if (ordered.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final state in ordered)
          _LegendItem(
            tones: colors.tonesFor(state),
            label: labels.forState(state),
            caption: colors.caption,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.tones,
    required this.label,
    required this.caption,
  });

  final SeatTones tones;
  final String label;
  final Color caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: tones.fill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            border: Border.all(color: tones.border),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: caption,
          ),
        ),
      ],
    );
  }
}
