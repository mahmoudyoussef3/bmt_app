import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// The stub below the ticket's tear line: what the seat costs, and the single
/// action that takes it.
///
/// A trip the rider has already booked stays bookable — booking a second seat
/// for a friend is a real thing riders do — but the button says so, so nobody
/// double-books by mistake.
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

    return Row(
      children: [
        Flexible(child: _Fare(price: trip.price)),
        const SizedBox(width: ClientSpacing.sm),
        _BookButton(trip: trip, label: label, onBook: onBook),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({
    required this.trip,
    required this.label,
    required this.onBook,
  });

  final UpcomingTripData trip;
  final String label;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);
    // A seat the rider already holds gets the quieter outlined button: the
    // action is still there, but it stops competing with the tickets they have
    // not booked yet.
    final isSecondary = trip.isBooked;

    return FilledButton(
      onPressed: trip.isSoldOut ? null : onBook,
      style: FilledButton.styleFrom(
        backgroundColor: isSecondary
            ? ClientColors.surfaceFor(context)
            : primary,
        foregroundColor: isSecondary ? primary : Colors.white,
        disabledBackgroundColor: ClientColors.surfaceMutedFor(context),
        disabledForegroundColor: ClientColors.textTertiaryFor(context),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.pill),
          side: isSecondary ? BorderSide(color: primary) : BorderSide.none,
        ),
        textStyle: ClientTypography.labelMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
      child: ConstrainedBox(
        // The label can grow ("Book another seat", and its Arabic), and the
        // ticket is only as wide as a rail card: let it ellipsize rather than
        // push the fare off its own stub.
        constraints: const BoxConstraints(maxWidth: 168),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

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
        const SizedBox(height: 1),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.priceMedium(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
      ],
    );
  }
}
