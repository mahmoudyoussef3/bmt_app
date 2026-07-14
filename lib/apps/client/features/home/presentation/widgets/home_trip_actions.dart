import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
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

  String get _label {
    if (trip.isSoldOut) return 'Sold out';
    return trip.isBooked ? 'Book another seat' : 'Book seat';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Fare(price: trip.price)),
        const SizedBox(width: ClientSpacing.sm),
        _BookButton(trip: trip, label: _label, onBook: onBook),
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
    // A repeat booking is offered, not pushed: it keeps the brand colour but
    // gives up the filled weight to the first-time booking action.
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.sm),
          side: isSecondary ? BorderSide(color: primary) : BorderSide.none,
        ),
        textStyle: ClientTypography.labelMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!trip.isSoldOut) ...[
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ],
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
        'Fare not published yet',
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FARE FROM',
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
