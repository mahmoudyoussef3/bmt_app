import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// [RouteOverviewScreen]'s compact duration/distance/seats fact row.
class RouteOverviewMetaRow extends StatelessWidget {
  const RouteOverviewMetaRow({super.key, required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(context, Icons.schedule_rounded, route.duration),
        _chip(context, Icons.straighten_rounded, route.distance),
        _chip(
          context,
          Icons.event_seat_rounded,
          context.l10n.booking_seatsCountLabel(route.availableSeats),
        ),
      ],
    );
  }

  Widget _chip(BuildContext ctx, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: ClientColors.textSecondaryFor(ctx)),
      const SizedBox(width: 4),
      Text(
        label,
        style: ClientTypography.labelSmall(
          ctx,
        ).copyWith(color: ClientColors.textSecondaryFor(ctx)),
      ),
    ],
  );
}
