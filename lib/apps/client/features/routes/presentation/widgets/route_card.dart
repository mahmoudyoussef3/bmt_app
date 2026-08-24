import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../domain/entities/route_summary.dart';
import 'route_card_body.dart';

/// One corridor in the routes catalog: where it goes, which towns it touches,
/// how far it runs, then — under a rule — who operates it and whether it is
/// selling seats today.
///
/// Shares its content with [HomeFeaturedRouteCard] via [RouteCardBody] so a
/// corridor looks like the same journey whether a rider meets it on Home's
/// featured shelf or here — only the card's overall size differs, and the
/// catalog's extra facts (the route's own name, the searched via-stop) come
/// with the roomier printing.
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.viaStop = '',
  });

  final RouteSummary route;

  /// An intermediate stop the rider's search matched — captioned so the
  /// corridor explains itself. Empty when the route matched on something the
  /// card already shows, or when nothing was searched at all.
  final String viaStop;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: RouteCardBody(route: route, viaStop: viaStop),
    );
  }
}
