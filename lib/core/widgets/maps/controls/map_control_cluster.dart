import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// A vertical stack of map controls: fit-route, zoom in/out, and an optional
/// follow-vehicle toggle. Deliberately not built from default
/// [FloatingActionButton]s — a custom rounded control cluster reads as part
/// of the map chrome rather than a generic Flutter action button.
class MapControlCluster extends StatelessWidget {
  const MapControlCluster({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onToggleFollow,
    this.followActive = false,
  });

  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  /// When provided, renders a follow-vehicle toggle above the other controls.
  final VoidCallback? onToggleFollow;
  final bool followActive;

  @override
  Widget build(BuildContext context) {
    final onToggleFollow = this.onToggleFollow;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggleFollow != null) ...[
          _ControlGroup(
            highlighted: followActive,
            children: [
              _ControlButton(
                icon: followActive
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                tooltip: followActive ? 'Following vehicle' : 'Follow vehicle',
                highlighted: followActive,
                onTap: onToggleFollow,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _ControlGroup(
          children: [
            _ControlButton(
              icon: Icons.center_focus_strong_rounded,
              tooltip: 'Fit route',
              onTap: onRecenter,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ControlGroup(
          children: [
            _ControlButton(
              icon: Icons.add_rounded,
              tooltip: 'Zoom in',
              onTap: onZoomIn,
            ),
            Container(
              width: 22,
              height: 1,
              color: MapStyle.border(context),
            ),
            _ControlButton(
              icon: Icons.remove_rounded,
              tooltip: 'Zoom out',
              onTap: onZoomOut,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.children, this.highlighted = false});

  final List<Widget> children;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primary
            : MapStyle.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? Colors.transparent
              : MapStyle.border(context),
        ),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        radius: 26,
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 22,
            color: highlighted
                ? Theme.of(context).colorScheme.onPrimary
                : MapStyle.onSurface(context),
          ),
        ),
      ),
    );
  }
}
