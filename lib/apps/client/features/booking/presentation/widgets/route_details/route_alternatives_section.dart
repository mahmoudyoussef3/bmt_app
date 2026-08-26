import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/alternative_route_tile.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_timeline_header.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The other lines that answer the same search, so a rider who decides this
/// one is wrong can switch without going back to the search screen.
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

    return ClientCard(
      padding: ClientSpacing.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteSectionHeader(
            icon: Icons.swap_horiz_rounded,
            title: context.l10n.booking_otherMatchingRoutes,
            subtitle: context.l10n.booking_closestRoutesForSearch,
            trailingLabel: '${alternatives.length}',
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 14),
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
      ),
    );
  }
}
