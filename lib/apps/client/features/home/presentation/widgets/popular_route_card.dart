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
    return SizedBox(
      width: width,
      height: listHeight,
      child: Material(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ClientColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        size: 21,
                        color: ClientColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        route.routeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.headingSmall(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RouteTimeline(context: context),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EndpointLabel(label: route.pickup),
                            const Spacer(),
                            _EndpointLabel(label: route.destination),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: ClientColors.borderFor(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RouteMetric(
                        label: 'From',
                        value: route.startingPrice,
                        emphasize: true,
                      ),
                    ),
                    _RouteMetric(
                      label: 'Duration',
                      value: route.duration.isEmpty
                          ? 'Not set'
                          : route.duration,
                    ),
                    const SizedBox(width: 14),
                    _RouteMetric(
                      label: 'Trips',
                      value: route.tripsAvailable.toString(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ClientColors.primaryLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: ClientColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: emphasize
              ? ClientTypography.priceMedium(context)
              : ClientTypography.labelLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: ClientColors.textPrimaryFor(context),
                ),
        ),
      ],
    );
  }
}

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
