import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

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
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: listHeight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withAlpha(10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ClientColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      size: 22,
                      color: ClientColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.headingSmall(context).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${route.tripsAvailable} trips available',
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RouteTimeline(context: context),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _EndpointLabel(label: route.pickup),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _EndpointLabel(label: route.destination),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                route.duration.isEmpty ? 'Not set' : route.duration,
                                style: ClientTypography.labelSmall(context).copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'From ',
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textTertiaryFor(context),
                    ),
                  ),
                  Text(
                    route.startingPrice,
                    style: ClientTypography.priceMedium(context).copyWith(
                      color: ClientColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _RouteMetric

class _EndpointLabel extends StatelessWidget {
  const _EndpointLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.headingSmall(context),
          ),
        ),
      ],
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          _TimelineDot(color: ClientColors.journeyGreen),
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                color: ClientColors.borderFor(context),
              ),
            ),
          ),
          _TimelineDot(color: ClientColors.journeyAmber),
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
