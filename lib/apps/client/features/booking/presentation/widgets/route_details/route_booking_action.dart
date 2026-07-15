import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Route Details' single, unambiguous sticky booking CTA (spec FR-006):
/// a summary of the selected route plus the one action that continues into
/// the existing booking wizard.
class RouteBookingAction extends StatelessWidget {
  const RouteBookingAction({
    super.key,
    required this.route,
    required this.onContinue,
  });

  final RouteOptionData? route;
  final ValueChanged<RouteOptionData> onContinue;

  @override
  Widget build(BuildContext context) {
    final selected = route;

    return BookingBottomAction(
      summary: selected == null ? null : _Summary(route: selected),
      child: ClientButton(
        label: selected == null
            ? context.l10n.booking_selectRoute
            : context.l10n.booking_continueWithThisRoute,
        icon: const DirectionalIcon(Icons.arrow_forward_rounded),
        onPressed: selected == null ? null : () => onContinue(selected),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.routeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${route.duration} · ${context.l10n.booking_seatsAvailableCount(route.availableSeats)}',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          route.startingPrice,
          style: ClientTypography.priceSmall(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
      ],
    );
  }
}
