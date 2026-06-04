import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

/// Compact route preview card for horizontal lists on Home.
class PopularRouteCard extends StatelessWidget {
  const PopularRouteCard({
    super.key,
    required this.route,
    required this.onTap,
    required this.width,
  });

  final PopularRouteData route;
  final VoidCallback onTap;

  /// Card width — set by [PopularRoutesPreview] from screen size.
  final double width;

  /// Cross-axis size for horizontal [ListView] parents.
  static const double listHeight = 152;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: listHeight,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppLayout.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DurationChip(duration: route.duration, scheme: scheme),
                const Spacer(),
                Icon(
                  Icons.directions_bus_filled_rounded,
                  size: 20,
                  color: scheme.primary.withAlpha(180),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spaceSm),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RouteTimeline(scheme: scheme),
                  const SizedBox(width: AppLayout.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EndpointLabel(label: route.pickup, scheme: scheme),
                        const Spacer(),
                        _EndpointLabel(
                          label: route.destination,
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            const SizedBox(height: AppLayout.spaceSm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: AppTypography.caption(
                          scheme,
                        ).copyWith(color: scheme.onSurface.withAlpha(150)),
                      ),
                      Text(
                        route.startingPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextThemes.priceEmphasis(
                          scheme,
                        ).copyWith(fontSize: 17, height: 1.2),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.duration, required this.scheme});

  final String duration;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceSm,
        vertical: AppLayout.spaceXs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: scheme.primary),
          const SizedBox(width: AppLayout.spaceXs),
          Text(
            duration,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          _TimelineDot(color: scheme.secondary),
          Expanded(
            child: Center(
              child: Container(width: 2, color: scheme.outline.withAlpha(80)),
            ),
          ),
          _TimelineDot(color: scheme.error),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(120), width: 2),
      ),
    );
  }
}

class _EndpointLabel extends StatelessWidget {
  const _EndpointLabel({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    );
  }
}
