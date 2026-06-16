import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Route discovery card for the client Home screen.
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
  static const double listHeight = 204;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: listHeight,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    size: 21,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    route.routeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 12),
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RouteMetric(
                    label: 'From',
                    value: route.startingPrice,
                    scheme: scheme,
                    emphasize: true,
                  ),
                ),
                _RouteMetric(
                  label: 'Duration',
                  value: route.duration.isEmpty ? 'Not set' : route.duration,
                  scheme: scheme,
                ),
                const SizedBox(width: 14),
                _RouteMetric(
                  label: 'Trips',
                  value: route.tripsAvailable.toString(),
                  scheme: scheme,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
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

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.scheme,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.caption(
            scheme,
          ).copyWith(color: scheme.onSurface.withAlpha(150), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: emphasize
              ? AppTextThemes.priceEmphasis(
                  scheme,
                ).copyWith(fontSize: 16, height: 1.1)
              : Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
        ),
      ],
    );
  }
}

class _EndpointLabel extends StatelessWidget {
  const _EndpointLabel({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
      ],
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
