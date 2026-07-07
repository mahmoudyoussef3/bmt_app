import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';

/// Start/End legend pill so the marker colors are immediately understandable.
class RouteMapLegendPill extends StatelessWidget {
  const RouteMapLegendPill({super.key});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: RouteMapStyle.start(context)),
          const SizedBox(width: 5),
          Text('Start', style: RouteMapStyle.pillLabel(context)),
          const SizedBox(width: 10),
          _LegendDot(color: RouteMapStyle.end(context)),
          const SizedBox(width: 5),
          Text('End', style: RouteMapStyle.pillLabel(context)),
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

/// A vertical stack of map controls: recenter to the route, zoom in, zoom out.
class RouteMapControls extends StatelessWidget {
  const RouteMapControls({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              color: RouteMapStyle.border(context),
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
  const _ControlGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RouteMapStyle.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RouteMapStyle.border(context)),
        boxShadow: RouteMapStyle.shadow(context),
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
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

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
          child: Icon(icon, size: 22, color: RouteMapStyle.onSurface(context)),
        ),
      ),
    );
  }
}

/// Basemap attribution required by OpenStreetMap + CARTO usage terms, with
/// OpenRouteService credited when its road geometry is on screen.
class RouteMapAttribution extends StatelessWidget {
  const RouteMapAttribution({super.key, this.showRouting = false});

  final bool showRouting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: RouteMapStyle.surface(context).withAlpha(210),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        showRouting
            ? '© OpenStreetMap · CARTO · openrouteservice'
            : '© OpenStreetMap · CARTO',
        style: AppTextThemes.badgeText(
          Theme.of(context).colorScheme,
        ).copyWith(fontSize: 9),
      ),
    );
  }
}

/// Shown when no stop has usable coordinates.
class RouteMapEmptyPanel extends StatelessWidget {
  const RouteMapEmptyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: RouteMapStyle.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  color: RouteMapStyle.onSurfaceMuted(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Map coordinates unavailable',
                textAlign: TextAlign.center,
                style: AppTextThemes.caption(Theme.of(context).colorScheme),
              ),
              const SizedBox(height: 4),
              Text(
                'The route details are still available below.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RouteMapStyle.onSurfaceMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: RouteMapStyle.surface(context).withAlpha(240),
        borderRadius: RouteMapStyle.pill,
        border: Border.all(color: RouteMapStyle.border(context)),
        boxShadow: RouteMapStyle.shadow(context),
      ),
      child: child,
    );
  }
}
