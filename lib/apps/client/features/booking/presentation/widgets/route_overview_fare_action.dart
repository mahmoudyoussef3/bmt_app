import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// [RouteOverviewScreen]'s bottom fare summary + "choose this route" action.
class RouteOverviewFareAction extends StatelessWidget {
  const RouteOverviewFareAction({
    super.key,
    required this.startingPrice,
    required this.onChooseRoute,
  });

  final String startingPrice;
  final VoidCallback onChooseRoute;

  @override
  Widget build(BuildContext context) {
    return BookingBottomAction(
      summary: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.booking_faresFrom,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
          Text(
            startingPrice,
            style: ClientTypography.priceSmall(
              context,
            ).copyWith(color: ClientColors.primary),
          ),
        ],
      ),
      child: ClientButton(
        label: context.l10n.booking_chooseThisRoute,
        icon: const DirectionalIcon(Icons.arrow_forward_rounded),
        onPressed: onChooseRoute,
      ),
    );
  }
}
