import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_route_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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
    final horizontalInset = AppLayout.spaceLg * 2;
    final gap = AppLayout.spaceMd;
    // ~88% of content width so the next card peeks on the edge.
    final cardWidth = ((screenWidth - horizontalInset - gap) * 0.88).clamp(
      272.0,
      340.0,
    );
    if (routes.isEmpty) return const SizedBox.shrink();
    
    final count = previewCount.clamp(1, routes.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context)!.home_popularRoutesTitle,
          subtitle: AppLocalizations.of(context)!.home_popularRoutesSubtitle,
          action: TextButton(
            onPressed: () => onOpenRoute(ClientRoutes.bookingPopularRoutes),
            child: Text(AppLocalizations.of(context)!.home_viewAll),
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
              final route = routes[index];
              return PopularRouteCard(
                route: route,
                width: cardWidth,
                onTap: () {
                  onOpenRoute(ClientRoutes.bookingRouteSelection, {
                    'pickup': route.pickup,
                    'destination': route.destination,
                    'date': 'Today, Jun 3',
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
