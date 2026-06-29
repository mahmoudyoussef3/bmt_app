import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_wizard_cubit.dart';

class WizardSummaryStep extends StatelessWidget {
  const WizardSummaryStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        final d = session.packageStartDate;
        final dateLabel = d == null ? '—' : '${d.day}/${d.month}/${d.year}';
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SectionCard(
                    title: 'Route',
                    icon: Icons.route_rounded,
                    rows: [
                      _Row('Route', session.route.routeName),
                      _Row('From', session.pickupStop?.name ?? '—'),
                      _Row('To', session.dropoffStop?.name ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Trip',
                    icon: Icons.directions_bus_rounded,
                    rows: [
                      _Row('Departure', session.selectedTrip?.departureTime ?? '—'),
                      _Row('Arrival', session.selectedTrip?.arrivalTime ?? '—'),
                      _Row('Vehicle type', session.selectedTrip?.vehicleType ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Seat',
                    icon: Icons.event_seat_rounded,
                    rows: [
                      _Row('Seat', session.selectedSeatLabel ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Package',
                    icon: Icons.card_membership_rounded,
                    rows: [
                      _Row('Plan', session.selectedPackage?.name ?? '—'),
                      _Row('Rides', '${session.selectedPackage?.tripsCount ?? 1}'),
                      _Row('Starts', dateLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PriceSummaryCard(session: session),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ClientButton(label: 'Proceed to Payment', onPressed: onNext),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: ClientColors.primary),
            const SizedBox(width: 8),
            Text(title, style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.primary, fontWeight: FontWeight.w700,
            )),
          ]),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text(r.label, style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                ))),
                Text(r.value, style: ClientTypography.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: ClientColors.textPrimaryFor(context),
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({required this.session});
  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final rides = session.selectedPackage?.tripsCount ?? 1;
    final discount = session.selectedPackage?.discountPercent ?? 0;
    final subtotal = session.tripPrice * rides;
    final saved = subtotal * discount / 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          _priceRow(context, 'Subtotal ($rides rides)', 'EGP ${subtotal.toStringAsFixed(0)}', false),
          if (discount > 0) _priceRow(context, 'Discount ($discount%)', '− EGP ${saved.toStringAsFixed(0)}', false, color: ClientColors.journeyGreen),
          const Divider(height: 20),
          _priceRow(context, 'Total', 'EGP ${session.totalPrice.toStringAsFixed(0)}', true),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext ctx, String label, String value, bool bold, {Color? color}) =>
      Row(children: [
        Expanded(child: Text(label, style: ClientTypography.bodySmall(ctx).copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? ClientColors.textPrimaryFor(ctx),
        ))),
        Text(value, style: ClientTypography.bodySmall(ctx).copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontSize: bold ? 16 : null,
          color: color ?? (bold ? ClientColors.primary : ClientColors.textPrimaryFor(ctx)),
        )),
      ]);
}
