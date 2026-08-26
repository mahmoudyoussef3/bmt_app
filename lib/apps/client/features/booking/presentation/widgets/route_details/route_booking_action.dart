import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_fact_line.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// Route Details' single, unambiguous sticky CTA (spec FR-006): a summary of
/// the line under review plus the one action that continues into the booking
/// wizard.
///
/// The summary names the line and how long it takes. It no longer carries a
/// fare: the price of a seat depends on the pickup and drop-off the rider
/// picks inside the wizard, so a figure on this bar would be advertising a
/// journey they have not chosen yet.
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
        Icon(
          Icons.alt_route_rounded,
          size: 18,
          color: ClientColors.primaryFor(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteDirectionText(
                origin: route.pickup,
                destination: route.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              RouteFactLine(
                facts: [
                  route.duration,
                  context.l10n.booking_seatsAvailableCount(
                    route.availableSeats,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
