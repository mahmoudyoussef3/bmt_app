import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/no_map_placeholder.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' map: a framed preview card, not a full-bleed backdrop.
///
/// The screen used to float a draggable sheet over a live map, which put the
/// two things in competition — the map was mostly covered, and every vertical
/// drag was ambiguous between panning it and moving the sheet. Here the map is
/// a fixed, **non-interactive** picture of the line that scrolls with the rest
/// of the content, and tapping it opens the full map screen where panning is
/// the only thing a drag can mean.
///
/// Falls back to [NoMapPlaceholder] when no stop on the route carries usable
/// coordinates (spec FR-007).
class RouteDetailsMapHero extends StatelessWidget {
  const RouteDetailsMapHero({
    super.key,
    required this.routeId,
    required this.mapPins,
    required this.stopCount,
    required this.onOpenMap,
  });

  final String routeId;
  final List<MapPinOption> mapPins;
  final int stopCount;
  final VoidCallback onOpenMap;

  static const double _height = 208;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.sm(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey(routeId),
            child: mapPins.isEmpty
                ? const NoMapPlaceholder()
                : EasyWayRouteMapView(
                    waypoints: mapPins,
                    interactive: false,
                    cameraPadding: const EdgeInsets.fromLTRB(36, 30, 36, 54),
                  ),
          ),
          if (stopCount > 0)
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 12,
              start: 12,
              child: _MapPill(
                icon: Icons.alt_route_rounded,
                label: stopCount == 1
                    ? context.l10n.booking_oneStop
                    : context.l10n.booking_stopsCountLabel(stopCount),
              ),
            ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            bottom: 12,
            end: 12,
            child: _MapPill(
              icon: Icons.open_in_full_rounded,
              label: context.l10n.booking_map,
              emphasized: true,
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onOpenMap,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A floating label over the map. Kept opaque rather than translucent so it
/// stays readable over whatever tile happens to sit behind it.
class _MapPill extends StatelessWidget {
  const _MapPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized
        ? ClientColors.onPrimaryFor(context)
        : ClientColors.textPrimaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? ClientColors.primaryFor(context)
            : ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        boxShadow: ClientElevation.sm(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: foreground, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
