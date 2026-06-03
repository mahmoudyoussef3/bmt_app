import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_mock_data.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/booking_flow_scaffold.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/popular_route_list_card.dart';

/// Full list of popular / most-used routes.
class PopularRoutesScreen extends StatelessWidget {
  const PopularRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = BookingSearchQuery.of(context);

    return BookingFlowScaffold(
      title: 'Popular Routes',
      query: query.isComplete ? query : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionHeader(
            title: 'Most used routes',
            subtitle: 'Frequently booked commutes across the network',
          ),
          const SizedBox(height: 12),
          ...kPopularRouteList.map((route) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PopularRouteListCard(
                route: route,
                onTap: () {
                  final updated = query.copyWith(
                    pickup: route.pickup,
                    destination: route.destination,
                  );
                  Navigator.pushNamed(
                    context,
                    BookingRoutes.routeSelection,
                    arguments: updated.toArguments(),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
