import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

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
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
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
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Trip',
                    icon: Icons.directions_bus_rounded,
                    rows: [
                      _Row(
                        'Departure',
                        session.selectedTrip?.departureTime ?? '—',
                      ),
                      _Row('Arrival', session.selectedTrip?.arrivalTime ?? '—'),
                      _Row(
                        'Vehicle type',
                        session.selectedTrip?.vehicleType ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: 'Seat',
                          icon: Icons.event_seat_rounded,
                          rows: [
                            _Row('Seat', session.selectedSeatLabel ?? '—'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SectionCard(
                          title: 'Package',
                          icon: Icons.card_membership_rounded,
                          rows: [
                            _Row('Plan', session.selectedPackage?.name ?? '—'),
                            _Row(
                              'Rides',
                              '${session.selectedPackage?.tripsCount ?? 1}',
                            ),
                            _Row('Starts', dateLabel),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _PriceSummaryCard(session: session),
                ],
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ClientButton(
                  label: 'Proceed to Payment',
                  onPressed: onNext,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: ClientColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ClientColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: ClientColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.label,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.value,
                      textAlign: TextAlign.right,
                      style: ClientTypography.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: ClientColors.textPrimaryFor(context),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final subtotal = session.tripPrice * rides;
    final saved = (subtotal - session.totalPrice).clamp(0, subtotal);
    final discount = subtotal <= 0 ? 0 : ((saved / subtotal) * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClientColors.primary.withValues(alpha: 0.12),
            ClientColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow(
            context,
            'Subtotal ($rides rides)',
            'EGP ${subtotal.toStringAsFixed(0)}',
            false,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _priceRow(
              context,
              'Discount ($discount%)',
              '− EGP ${saved.toStringAsFixed(0)}',
              false,
              color: ClientColors.journeyGreen,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1),
          ),
          _priceRow(
            context,
            'Total',
            'EGP ${session.totalPrice.toStringAsFixed(0)}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext ctx,
    String label,
    String value,
    bool bold, {
    Color? color,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: ClientTypography.bodyMedium(ctx).copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color:
                color ??
                (bold
                    ? ClientColors.textPrimaryFor(ctx)
                    : ClientColors.textSecondaryFor(ctx)),
          ),
        ),
      ),
      Text(
        value,
        style: ClientTypography.headingSmall(ctx).copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color:
              color ??
              (bold ? ClientColors.primary : ClientColors.textPrimaryFor(ctx)),
        ),
      ),
    ],
  );
}
