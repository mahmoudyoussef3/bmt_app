import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../domain/entities/office_route.dart';
import 'office_route_tile.dart';

/// The corridors this office runs, as a stack of tappable route tiles.
class OfficeRoutesSection extends StatelessWidget {
  const OfficeRoutesSection({
    super.key,
    required this.routes,
    required this.onOpenRoute,
  });

  final List<OfficeRoute> routes;
  final ValueChanged<OfficeRoute> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, route) in routes.indexed) ...[
          if (index > 0) const SizedBox(height: ClientSpacing.xs),
          OfficeRouteTile(route: route, onTap: () => onOpenRoute(route)),
        ],
      ],
    );
  }
}
