import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

class WizardTripStep extends StatelessWidget {
  const WizardTripStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        final trips = session.route.availableTrips;
        if (trips.isEmpty) {
          return _EmptyTrips(routeName: session.route.routeName);
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: trips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TripCard(
                  trip: trips[i],
                  isSelected: session.selectedTrip?.id == trips[i].id,
                  onTap: () => context.read<BookingWizardCubit>().selectTrip(trips[i]),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ClientButton(
                  label: 'Continue',
                  onPressed: session.tripValid ? onNext : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.isSelected, required this.onTap});
  final RouteTripOptionData trip;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? ClientColors.primary : ClientColors.borderFor(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ClientColors.primaryLight : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trip.departureTime,
                        style: ClientTypography.headingSmall(context).copyWith(
                          color: ClientColors.textPrimaryFor(context),
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: ClientColors.journeySlate),
                    const SizedBox(width: 8),
                    Text(trip.arrivalTime,
                        style: ClientTypography.bodyMedium(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(context, Icons.directions_bus_rounded, trip.vehicleType),
                    const SizedBox(width: 8),
                    _chip(context, Icons.event_seat_rounded, '${trip.availableSeats} seats'),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EGP ${trip.price}',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: isSelected ? ClientColors.primary : ClientColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('per ride', style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                )),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle_rounded, color: ClientColors.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: ClientColors.textSecondaryFor(context)),
      const SizedBox(width: 4),
      Text(label, style: ClientTypography.labelSmall(context).copyWith(
        color: ClientColors.textSecondaryFor(context),
      )),
    ],
  );
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus_outlined, size: 64, color: ClientColors.journeySlate),
            const SizedBox(height: 16),
            Text('No trips available', style: ClientTypography.headingSmall(context)),
            const SizedBox(height: 8),
            Text('No trips found for $routeName today.',
                textAlign: TextAlign.center,
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                )),
          ],
        ),
      ),
    );
  }
}
