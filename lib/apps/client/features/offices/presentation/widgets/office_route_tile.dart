import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/office_route.dart';

/// One corridor this office runs. Tapping it drops the rider into the
/// existing booking search, pre-filtered to exactly this route.
///
/// Drawn as an origin→destination spine rather than a line of text: a corridor
/// is two endpoints, and the stacked form survives long Arabic city names on a
/// narrow phone where "A → B" on one line ellipsises the destination away.
class OfficeRouteTile extends StatelessWidget {
  const OfficeRouteTile({super.key, required this.route, required this.onTap});

  final OfficeRoute route;
  final VoidCallback onTap;

  bool get _hasEndpoints =>
      route.startCity.isNotEmpty && route.endCity.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Row(
        children: [
          if (_hasEndpoints) ...[
            _RouteSpine(accent: accent),
            const SizedBox(width: ClientSpacing.md),
          ] else ...[
            Icon(Icons.route_rounded, color: accent),
            const SizedBox(width: ClientSpacing.md),
          ],
          Expanded(
            child: _hasEndpoints
                ? _Endpoints(route: route)
                : Text(
                    route.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          DirectionalIcon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: ClientColors.textTertiaryFor(context),
          ),
        ],
      ),
    );
  }
}

/// The two endpoint names, with the route's own label kept as a muted eyebrow
/// when the office named it something the cities don't already say.
class _Endpoints extends StatelessWidget {
  const _Endpoints({required this.route});

  final OfficeRoute route;

  /// Offices commonly name a route after its endpoints; repeating that above
  /// the spine would be the same fact twice.
  bool get _nameAddsSomething {
    final name = route.name.trim();
    if (name.isEmpty) return false;
    return !(name.contains(route.startCity) && name.contains(route.endCity));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = ClientTypography.bodyMedium(context).copyWith(
      fontWeight: FontWeight.w800, 
      height: 1.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_nameAddsSomething) ...[
          Text(
            route.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          route.startCity,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          route.endCity,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      ],
    );
  }
}

/// Dot — line — dot, the corridor as a diagram.
class _RouteSpine extends StatelessWidget {
  const _RouteSpine({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: accent, filled: false),
        Container(
          width: 2, 
          height: 18, 
          color: accent.withAlpha(50),
          margin: const EdgeInsets.symmetric(vertical: 2),
        ),
        _Dot(color: accent, filled: true),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(
          color: color, 
          width: filled ? 0 : 2,
        ),
      ),
    );
  }
}
