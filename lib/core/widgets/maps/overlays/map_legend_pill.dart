import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Start/End legend pill so the marker colors are immediately understandable.
class MapLegendPill extends StatelessWidget {
  const MapLegendPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(240),
        borderRadius: MapStyle.pill,
        border: Border.all(color: MapStyle.border(context)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: MapStyle.start(context)),
          const SizedBox(width: 5),
          Text('Start', style: MapStyle.pillLabel(context)),
          const SizedBox(width: 10),
          _LegendDot(color: MapStyle.end(context)),
          const SizedBox(width: 5),
          Text('End', style: MapStyle.pillLabel(context)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
