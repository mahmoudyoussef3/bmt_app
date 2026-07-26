import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';

/// The captain map's floating controls and attribution, lifted above the fixed
/// pickup panel so neither is buried under it. Reuses the shared control cluster
/// so the captain and client maps carry the same recenter/zoom/follow chrome.
class CaptainMapChrome extends StatelessWidget {
  const CaptainMapChrome({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleFollow,
    required this.followActive,
    required this.showRouting,
    this.bottomInset = 12,
  });

  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleFollow;
  final bool followActive;
  final bool showRouting;

  /// How far above the map's bottom edge the chrome sits — the pickup panel's
  /// height, so the controls ride just over it.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PositionedDirectional(
          end: 12,
          bottom: bottomInset + 12,
          child: MapControlCluster(
            onRecenter: onRecenter,
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
            onToggleFollow: onToggleFollow,
            followActive: followActive,
          ),
        ),
        PositionedDirectional(
          start: 12,
          bottom: bottomInset + 12,
          child: MapAttribution(showRouting: showRouting),
        ),
      ],
    );
  }
}
