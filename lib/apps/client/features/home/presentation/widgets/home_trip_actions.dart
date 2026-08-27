import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// The stub below the ticket's tear line: what the seat costs, and the single
/// action that takes it.
///
/// The fare is stated on its own line and the action gets the card's full
/// width, the way every other primary action in the client app is drawn — a
/// price and a button fighting for one row meant the button had to be capped
/// and ellipsised, and "Book another seat" (or its Arabic) lost half of itself
/// on a narrow phone.
///
/// A trip the rider has already booked stays bookable — booking a second seat
/// for a friend is a real thing riders do — but it takes the quieter outlined
/// button, so on a board of departures the unbooked ones are the ones offering.
class HomeTripCta extends StatelessWidget {
  const HomeTripCta({super.key, required this.trip, required this.onBook});

  final UpcomingTripData trip;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = trip.isSoldOut
        ? l10n.common_soldOut
        : trip.isBooked
        ? l10n.home_bookAnotherSeat
        : l10n.home_bookSeat;
    final onPressed = trip.isSoldOut ? null : onBook;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Fare(price: trip.price),
        const SizedBox(height: ClientSpacing.sm),
        if (trip.isBooked)
          ClientButton.secondary(label: label, onPressed: onPressed)
        else
          ClientButton(label: label, onPressed: onPressed),
      ],
    );
  }
}

/// What a seat on this departure costs, as one line: the caption that qualifies
/// the number, then the number itself at the size a price is read at.
class _Fare extends StatelessWidget {
  const _Fare({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    if (price.isEmpty) {
      return Text(
        context.l10n.home_fareNotPublished,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          context.l10n.home_fareFrom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.priceMedium(
              context,
            ).copyWith(color: ClientColors.primaryFor(context)),
          ),
        ),
      ],
    );
  }
}
