import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../domain/entities/route_summary.dart';
import 'route_card.dart';

/// The scrollable list of routes.
class RoutesDirectoryList extends StatelessWidget {
  const RoutesDirectoryList({
    super.key,
    required this.routes,
    required this.onOpenRoute,
  });

  final List<RouteSummary> routes;
  final ValueChanged<RouteSummary> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.xl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: routes.length,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (context, index) => RouteCard(
        route: routes[index],
        onTap: () => onOpenRoute(routes[index]),
      ),
    );
  }
}
