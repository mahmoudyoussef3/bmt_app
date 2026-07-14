import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_ticket_facts.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_ticket_journey.dart';

/// What the rider is about to buy, drawn as the ticket they will end up
/// holding. A table of the fields they already typed is something to proofread;
/// the ticket itself is something to recognise — which is what makes a payment
/// screen feel safe to press.
class CheckoutTicketCard extends StatelessWidget {
  const CheckoutTicketCard({super.key, required this.data});

  final PaymentCheckoutData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        boxShadow: ClientElevation.md(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        child: ColoredBox(
          color: ClientColors.surfaceFor(context),
          child: Column(
            children: [
              _Header(data: data),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: CheckoutTicketJourney(data: data),
              ),
              const TicketTearLine(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: CheckoutTicketFacts(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tinted band: the seat being held, and the day it is held for.
class _Header extends StatelessWidget {
  const _Header({required this.data});

  final PaymentCheckoutData data;

  @override
  Widget build(BuildContext context) {
    final day = formatTripDay(context, data.tripDate);
    final seat = data.selectedSeat.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: ClientColors.primaryGradientFor(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your seat',
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 3),
                Text(
                  seat.isEmpty ? 'Seat not selected' : 'Seat $seat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (day.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(46),
                borderRadius: BorderRadius.circular(ClientRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    day,
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
