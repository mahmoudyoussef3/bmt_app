import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Minutes to the next stop, as a chip — the one number the rider is after.
class TrackingEtaBadge extends StatelessWidget {
  const TrackingEtaBadge({super.key, required this.eta});

  final DateTime? eta;

  @override
  Widget build(BuildContext context) {
    final minutes = eta?.difference(DateTime.now()).inMinutes;
    final (value, unit) = switch (minutes) {
      null => ('--', ''),
      <= 0 => ('Now', ''),
      > 90 => ((minutes / 60).toStringAsFixed(1), 'hr'),
      _ => ('$minutes', 'min'),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1,
            color: ClientColors.primary,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: MapStyle.onSurfaceMuted(context),
            ),
          ),
      ],
    );
  }
}

/// Live / stale GPS state, as a dot and a word.
class TrackingSignalChip extends StatelessWidget {
  const TrackingSignalChip({
    super.key,
    required this.sample,
    required this.completed,
  });

  final VehicleSample? sample;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (completed) return const SizedBox.shrink();
    final current = sample;
    final (tone, label) = switch (current) {
      null => (ClientColors.journeySlate, 'No signal'),
      _ when current.isStale => (ClientColors.journeyRed, 'No signal'),
      _ when current.isMoving => (
        ClientColors.journeyCyan,
        '${current.speedKmh.round()} km/h',
      ),
      _ => (ClientColors.journeyCyan, 'Stopped'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
