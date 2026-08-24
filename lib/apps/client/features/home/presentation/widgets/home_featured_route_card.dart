import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/route_card_body.dart';

/// One corridor on Home's featured-routes shelf, as a tighter printing of the
/// same card the routes catalog uses ([RouteCardBody]).
///
/// Home is a shortcut into the catalog, not a second catalog: a rider who
/// picks a corridor off this shelf should recognise it instantly in the routes
/// tab, so the two share one card and differ only in size.
class HomeFeaturedRouteCard extends StatelessWidget {
  const HomeFeaturedRouteCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  final RouteSummary route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: RouteCardBody(route: route, dense: true),
    );
  }
}
