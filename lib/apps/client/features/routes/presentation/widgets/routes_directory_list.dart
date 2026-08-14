import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../domain/entities/route_search_match.dart';
import '../../domain/entities/route_summary.dart';
import 'route_card.dart';

/// The scrollable list of routes.
class RoutesDirectoryList extends StatelessWidget {
  const RoutesDirectoryList({
    super.key,
    required this.matches,
    required this.onOpenRoute,
  });

  /// The catalog's current results — each route plus why it is listed, so a
  /// corridor found through a town it only passes through can say so.
  final List<RouteSearchMatch> matches;

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
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (context, index) {
        final match = matches[index];
        return RouteCard(
          route: match.route,
          viaStop: match.viaStop,
          onTap: () => onOpenRoute(match.route),
        );
      },
    );
  }
}
