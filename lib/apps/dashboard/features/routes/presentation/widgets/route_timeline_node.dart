import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

/// Where a point sits in the journey, which is the only thing the timeline
/// colours encode.
enum RouteTimelineRole {
  origin,
  waypoint,
  destination;

  static RouteTimelineRole at(int index, int total) {
    if (index == 0) return RouteTimelineRole.origin;
    if (index == total - 1) return RouteTimelineRole.destination;
    return RouteTimelineRole.waypoint;
  }

  bool get isEndpoint => this != RouteTimelineRole.waypoint;
}

/// Brand blue starts the journey, cyan ends it — the same pair the rider's app
/// uses for pickup and drop-off, so an operator and a rider looking at the same
/// route see the same two colours mean the same two things. Nothing on a route
/// is ever drawn in the error red; a route has no failure state.
Color routeRoleColor(BuildContext context, RouteTimelineRole role) {
  final scheme = Theme.of(context).colorScheme;
  return switch (role) {
    RouteTimelineRole.origin => scheme.primary,
    RouteTimelineRole.waypoint => scheme.onSurfaceVariant,
    RouteTimelineRole.destination => scheme.secondary,
  };
}

/// One node of a route timeline: a filled endpoint marker, or a numbered ring
/// for a stop on the way.
class RouteTimelineDot extends StatelessWidget {
  final RouteTimelineRole role;

  /// 1-based position, shown inside waypoint rings.
  final int position;
  final double size;

  const RouteTimelineDot({
    super.key,
    required this.role,
    required this.position,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = routeRoleColor(context, role);

    if (role.isEndpoint) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 2),
        ),
        child: Icon(
          role == RouteTimelineRole.origin
              ? Icons.trip_origin_rounded
              : Icons.flag_rounded,
          size: size * 0.5,
          color: role == RouteTimelineRole.origin
              ? scheme.onPrimary
              : scheme.onSecondary,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline.withAlpha(120), width: 2),
      ),
      child: Text(
        '$position',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The rail between two nodes.
class RouteTimelineConnector extends StatelessWidget {
  final double height;

  const RouteTimelineConnector({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 2,
      height: height,
      color: scheme.outline.withAlpha(90),
    );
  }
}

/// "الموقع محدد" / "الموقع غير محدد", in the same neutral weight either way.
///
/// A stop without coordinates is a complete, bookable stop — the dashboard used
/// to paint it in `errorContainer` with a red ring, which told operators they
/// had broken something they had not.
class RouteLocationChip extends StatelessWidget {
  final bool located;

  const RouteLocationChip({super.key, required this.located});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(located ? 90 : 55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            located ? Icons.place_rounded : Icons.place_outlined,
            size: 13,
            color: located ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xSmall),
          Text(
            located ? 'الموقع محدد' : 'الموقع غير محدد',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// `بنها ← شبين القناطر ← القاهرة`, wrapping instead of truncating so the whole
/// journey is readable on a narrow card.
class RouteDirectionChain extends StatelessWidget {
  final List<String> stops;
  final TextStyle? style;
  final int? maxLines;

  const RouteDirectionChain({
    super.key,
    required this.stops,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final names = stops.where((name) => name.trim().isNotEmpty).toList();
    if (names.isEmpty) return const SizedBox.shrink();

    final base =
        style ??
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Text.rich(
      TextSpan(
        children: [
          for (final entry in names.indexed) ...[
            if (entry.$1 != 0)
              TextSpan(
                // U+2190 keeps the arrow pointing along the reading direction
                // in an RTL layout; a Latin "→" would flip and reverse the
                // route's meaning.
                text: ' ← ',
                style: base?.copyWith(color: scheme.outline),
              ),
            TextSpan(
              text: entry.$2.trim(),
              style: entry.$1 == 0 || entry.$1 == names.length - 1
                  ? base?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    )
                  : base,
            ),
          ],
        ],
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
