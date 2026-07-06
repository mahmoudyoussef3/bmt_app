import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_route_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Horizontal popular routes strip with responsive card sizing.
class PopularRoutesPreview extends StatelessWidget {
  const PopularRoutesPreview({
    super.key,
    required this.onOpenRoute,
    required this.routes,
    this.previewCount = 2,
  });

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final List<PopularRouteData> routes;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 720;
    final horizontalInset = AppLayout.spaceLg * 2;
    final gap = AppLayout.spaceMd;
    // ~88% of content width so the next card peeks on the edge.
    final cardWidth =
        ((screenWidth - horizontalInset - gap) * (isTablet ? 0.48 : 0.88))
            .clamp(272.0, 360.0);

    final count = routes.isEmpty ? 0 : previewCount.clamp(1, routes.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (routes.isEmpty)
          _EmptyPopularRoutes(
            onBrowse: () => onOpenRoute(ClientRoutes.bookingPopularRoutes),
          )
        else
          SizedBox(
            height: PopularRouteCard.listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: count,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppLayout.spaceMd),
              itemBuilder: (context, index) {
                final route = routes[index];
                return PopularRouteCard(
                  route: route,
                  width: cardWidth,
                  onTap: () {
                    onOpenRoute(ClientRoutes.bookingRouteSelection, {
                      'routeId': route.id,
                      'pickup': route.pickup,
                      'destination': route.destination,
                      'time': '',
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyPopularRoutes extends StatelessWidget {
  const _EmptyPopularRoutes({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.route_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active routes yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  'Routes created in the dashboard will appear here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onBrowse, child: const Text('Browse')),
        ],
      ),
    );
  }
}
