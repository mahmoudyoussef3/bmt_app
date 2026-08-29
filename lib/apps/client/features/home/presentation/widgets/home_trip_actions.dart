import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// The action on the ticket stub: one compact control, sized to its label.
///
/// [ClientButton.dense] rather than the full-width CTA. The stub is one row —
/// the fare on the leading edge, this on the trailing one — so the button is a
/// 44pt control that shares the line instead of a 52pt bar that owns a row of
/// its own on a card a rider is only browsing.
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

    if (trip.isBooked) {
      return ClientButton.secondary(
        label: label,
        onPressed: onPressed,
        expand: false,
        dense: true,
      );
    }

    return ClientButton(
      label: label,
      onPressed: onPressed,
      expand: false,
      dense: true,
    );
  }
}

/// What a seat on this departure costs: the caption that qualifies the number
/// stacked over the number itself.
///
/// Stacked rather than run together on one line, because the qualifier is a
/// phrase in both languages ("FARE FROM", "السعر يبدأ من") and a fare that has
/// to share a row with it ends up ellipsised on a narrow phone. The stack is
/// shorter than the button beside it, so the two lines cost the card nothing.
class HomeTripFare extends StatelessWidget {
  const HomeTripFare({super.key, required this.price});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.priceSmall(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ClientColors.primaryFor(context),
          ),
        ),
      ],
    );
  }
}
