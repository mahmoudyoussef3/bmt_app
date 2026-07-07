import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/alternative_route_tile.dart';

/// "Other matching routes" — every alternative route for the current search.
class RouteAlternativesSection extends StatelessWidget {
  const RouteAlternativesSection({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
  });

  final List<RouteOptionData> routes;
  final String selectedRouteId;
  final ValueChanged<RouteOptionData> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final alternatives = routes
        .where((route) => route.id != selectedRouteId)
        .toList();
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other matching routes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...alternatives.map(
          (route) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AlternativeRouteTile(
              route: route,
              onTap: () => onSelectRoute(route),
            ),
          ),
        ),
      ],
    );
  }
}
