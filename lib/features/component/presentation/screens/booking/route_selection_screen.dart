import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_mock_data.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/booking_flow_scaffold.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/route_option_card.dart';

/// Lists available route options for the current search.
class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  late BookingSearchQuery _query;
  String? _selectedRouteId;
  late List<RouteOptionData> _routes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = BookingSearchQuery.of(context);
    _routes = mockRoutesFor(_query);
    _selectedRouteId ??= _routes.first.id;
  }

  void _continueToTrips() {
    Navigator.pushNamed(
      context,
      BookingRoutes.vehicleListing,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BookingFlowScaffold(
      title: 'Select Route',
      query: _query,
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppButton(
            label: 'Compare Vehicles',
            height: 52,
            onPressed: _selectedRouteId == null ? () {} : _continueToTrips,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          SectionHeader(
            title: 'Available routes',
            subtitle: '${_routes.length} options for your search',
            action: TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  BookingRoutes.mapSelection,
                  arguments: _query.toArguments(),
                );
              },
              child: const Text('Map'),
            ),
          ),
          const SizedBox(height: 12),
          ..._routes.map((route) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RouteOptionCard(
                route: route,
                selected: _selectedRouteId == route.id,
                onTap: () => setState(() => _selectedRouteId = route.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}
