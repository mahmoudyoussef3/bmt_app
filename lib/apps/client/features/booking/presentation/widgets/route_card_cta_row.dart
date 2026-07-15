import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The bottom "next action" row of [PopularRouteListCard]: hint text plus a
/// directional arrow badge.
class RouteCardCtaRow extends StatelessWidget {
  const RouteCardCtaRow({super.key, required this.hasTrips});

  final bool hasTrips;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hasTrips
                ? context.l10n.booking_chooseTripTimeAndVehicle
                : context.l10n.booking_viewRouteDetails,
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasTrips
                ? ClientColors.primary
                : ClientColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DirectionalIcon(
            Icons.arrow_forward_rounded,
            color: hasTrips
                ? Colors.white
                : ClientColors.textSecondaryFor(context),
            size: 20,
          ),
        ),
      ],
    );
  }
}
