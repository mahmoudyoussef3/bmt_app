import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/popular_route_card.dart';

/// Horizontal popular routes strip with responsive card sizing.
class PopularRoutesPreview extends StatelessWidget {
  const PopularRoutesPreview({
    super.key,
    required this.onOpenRoute,
    this.previewCount = 2,
  });

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = AppLayout.spaceLg * 2;
    final gap = AppLayout.spaceMd;
    // ~88% of content width so the next card peeks on the edge.
    final cardWidth = ((screenWidth - horizontalInset - gap) * 0.88).clamp(
      272.0,
      340.0,
    );
    final count = previewCount.clamp(1, kPopularRoutes.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Popular routes',
          subtitle: 'Frequent commutes from your area',
          action: TextButton(
            onPressed: () => onOpenRoute(BookingRoutes.popularRoutes),
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: AppLayout.spaceMd),
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
              final route = kPopularRoutes[index];
              return PopularRouteCard(
                route: route,
                width: cardWidth,
                onTap: () {
                  onOpenRoute(
                    BookingRoutes.routeSelection,
                    BookingSearchQuery(
                      pickup: route.pickup,
                      destination: route.destination,
                    ).toArguments(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
