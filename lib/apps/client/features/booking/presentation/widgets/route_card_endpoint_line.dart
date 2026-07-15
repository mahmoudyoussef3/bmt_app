import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_line_dots.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The vertical "from → to" line with origin/destination dots, used inside
/// [PopularRouteListCard] to visualize a route's endpoints at a glance.
class RouteEndpointLine extends StatelessWidget {
  const RouteEndpointLine({
    super.key,
    required this.pickup,
    required this.destination,
    required this.active,
  });

  final String pickup;
  final String destination;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RouteLine(active: active),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Endpoint(label: context.l10n.booking_from, value: pickup),
                const SizedBox(height: 12),
                _Endpoint(label: context.l10n.booking_to, value: destination),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? context.l10n.common_notSet : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context),
        ),
      ],
    );
  }
}
