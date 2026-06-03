import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

class PopularRouteCard extends StatelessWidget {
  const PopularRouteCard({super.key, required this.route, required this.onTap});

  final PopularRouteData route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.duration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(170),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RouteEndpoint(
              icon: Icons.trip_origin_rounded,
              color: scheme.secondary,
              label: 'Pickup',
              value: route.pickup,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(
                width: 2,
                height: 14,
                color: scheme.outline.withAlpha(120),
              ),
            ),
            _RouteEndpoint(
              icon: Icons.location_on_rounded,
              color: scheme.tertiary,
              label: 'Destination',
              value: route.destination,
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface.withAlpha(140),
                      ),
                    ),
                    Text(
                      route.startingPrice,
                      style: AppTextThemes.priceEmphasis(
                        scheme,
                      ).copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
