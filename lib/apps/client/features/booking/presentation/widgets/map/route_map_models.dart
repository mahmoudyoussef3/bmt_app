import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A single mapped stop: its coordinate and (optional) display name.
class RouteMapStop {
  const RouteMapStop({required this.coordinate, this.name = ''});

  final LatLng coordinate;
  final String name;
}

/// Shared visual tokens for the route map so the layer, marker and overlay
/// pieces stay in sync (colors, labels, casing, pills).
class RouteMapStyle {
  const RouteMapStyle._();

  static Color start(BuildContext context) => ClientColors.journeyGreen;

  static Color end(BuildContext context) => Theme.of(context).colorScheme.error;

  static Color stop(BuildContext context) => ClientColors.primaryFor(context);

  static Color routeLine(BuildContext context) =>
      ClientColors.primaryFor(context);

  /// Marker fill color by position along the ordered route.
  static Color colorFor(BuildContext context, int index, int count) {
    if (index == 0) return start(context);
    if (index == count - 1) return end(context);
    return stop(context);
  }

  /// Short badge shown inside the marker (A · B · stop number).
  static String labelFor(int index, int count) {
    if (index == 0) return 'A';
    if (index == count - 1) return 'B';
    return '${index + 1}';
  }

  /// Human role used in the tap callout.
  static String roleFor(int index, int count) {
    if (index == 0) return 'Start';
    if (index == count - 1) return 'Destination';
    return 'Stop $index';
  }

  static IconData iconFor(int index, int count) {
    if (index == 0) return Icons.trip_origin_rounded;
    if (index == count - 1) return Icons.flag_rounded;
    return Icons.circle;
  }

  static Color surface(BuildContext context) =>
      ClientColors.surfaceFor(context);

  static Color border(BuildContext context) => ClientColors.borderFor(context);

  static Color onSurface(BuildContext context) =>
      ClientColors.textPrimaryFor(context);

  static Color onSurfaceMuted(BuildContext context) =>
      ClientColors.textSecondaryFor(context);

  static List<BoxShadow> shadow(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(55),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static BorderRadius get pill => BorderRadius.circular(ClientRadius.pill);

  static TextStyle pillLabel(BuildContext context) =>
      ClientTypography.labelSmall(
        context,
      ).copyWith(fontWeight: FontWeight.w800);
}
