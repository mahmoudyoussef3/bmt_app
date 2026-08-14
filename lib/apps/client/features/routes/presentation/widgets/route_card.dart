import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/route_summary.dart';

/// One corridor in the routes catalog, as an origin→destination spine with
/// its distance/duration and operating office underneath.
///
/// Drawn the same way [OfficeRouteTile] draws a corridor: two endpoints are
/// two lines, not one ellipsised "A → B" that loses the destination on a
/// narrow phone with long Arabic city names.
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.viaStop = '',
  });

  final RouteSummary route;

  /// An intermediate stop the rider's search matched — captioned under the
  /// endpoints so the corridor explains itself. Empty when the route matched
  /// on something the card already shows, or when nothing was searched at all.
  final String viaStop;

  final VoidCallback onTap;

  bool get _hasEndpoints =>
      route.startCity.isNotEmpty && route.endCity.isNotEmpty;

  bool get _hasMeta => route.distance.isNotEmpty || route.duration.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: ClientTypography.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: ClientSpacing.xs),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClientColors.primaryContainerFor(context),
                ),
                child: DirectionalIcon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: ClientColors.onPrimaryContainerFor(context),
                ),
              ),
            ],
          ),
          if (viaStop.isNotEmpty) ...[
            const SizedBox(height: ClientSpacing.sm),
            _ViaStopTag(stopName: viaStop),
          ],
          if (_hasMeta || route.officeName.isNotEmpty) ...[
            const SizedBox(height: ClientSpacing.sm),
            Row(
              children: [
                if (route.distance.isNotEmpty)
                  _MetaChip(icon: Icons.route_outlined, label: route.distance),
                if (route.distance.isNotEmpty && route.duration.isNotEmpty)
                  const SizedBox(width: ClientSpacing.xs),
                if (route.duration.isNotEmpty)
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: route.duration,
                  ),
                if (route.officeName.isNotEmpty) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      route.officeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.textTertiaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "يمر عبر بنها" — why this corridor is in the results when neither of its
/// endpoints is what the rider typed.
///
/// Sits below the endpoints rather than beside them: a stop on the way is a
/// fact about the journey, not a third terminus, and putting it on the spine
/// would read as one. Hugs its text so it reads as a tag on the card, not as
/// another field.
class _ViaStopTag extends StatelessWidget {
  const _ViaStopTag({required this.stopName});

  final String stopName;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withAlpha(20),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.routes_viaStation(stopName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ClientColors.textTertiaryFor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _Endpoints extends StatelessWidget {
  const _Endpoints({required this.route});

  final RouteSummary route;

  /// Offices commonly name a route after its endpoints; repeating that above
  /// the spine would be the same fact twice.
  bool get _nameAddsSomething {
    final name = route.name.trim();
    if (name.isEmpty) return false;
    return !(name.contains(route.startCity) && name.contains(route.endCity));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = ClientTypography.bodyMedium(
      context,
    ).copyWith(fontWeight: FontWeight.w800, height: 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_nameAddsSomething) ...[
          Text(
            route.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
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
          width: 3,
          height: 24,
          color: accent.withAlpha(100),
          margin: const EdgeInsets.symmetric(vertical: 4),
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
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: filled ? 0 : 3),
      ),
    );
  }
}
