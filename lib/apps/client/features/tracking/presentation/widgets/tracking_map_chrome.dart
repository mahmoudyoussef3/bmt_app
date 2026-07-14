import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';

/// The live map's floating controls and attribution.
///
/// Both ride just above the details sheet instead of sitting at a fixed spot:
/// with the sheet open, controls pinned to the map's own bottom edge are
/// simply buried under it, and controls parked mid-screen (where they used to
/// be) read as debris floating over the route.
class TrackingMapChrome extends StatelessWidget {
  const TrackingMapChrome({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleFollow,
    required this.followActive,
    required this.showRouting,
    this.sheetController,
  });

  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleFollow;
  final bool followActive;
  final bool showRouting;
  final DraggableScrollableController? sheetController;

  @override
  Widget build(BuildContext context) {
    final controller = sheetController;
    if (controller == null) return _chrome(context, 12);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _chrome(context, _lift(context, controller)),
    );
  }

  /// How far above the map's bottom edge the chrome sits: the sheet's current
  /// height, capped at half the screen so a rider who drags the sheet up to
  /// read the timeline doesn't send the zoom buttons into the route.
  double _lift(BuildContext context, DraggableScrollableController controller) {
    if (!controller.isAttached) return 12;
    final fraction = controller.size.clamp(0.0, 0.5);
    return fraction * MediaQuery.sizeOf(context).height + 12;
  }

  Widget _chrome(BuildContext context, double lift) {
    return Stack(
      children: [
        PositionedDirectional(
          end: 12,
          bottom: lift,
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
          bottom: lift,
          child: MapAttribution(showRouting: showRouting),
        ),
      ],
    );
  }
}

/// A soft top scrim so the status card and the floating app-bar buttons keep
/// their contrast over pale basemap tiles without tinting the whole map.
class TrackingMapTopScrim extends StatelessWidget {
  const TrackingMapTopScrim({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(28),
              Colors.black.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}
