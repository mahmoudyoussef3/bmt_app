import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_qr_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Full trip details with QR, payment, cancel & review flows (UI only).
class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, this.tripId});

  final String? tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  String? _tripId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tripId = _resolveTripId(context);
    if (_tripId == tripId) return;
    _tripId = tripId;
    context.read<TripsCubit>().loadTripDetails(_tripId);
  }

  String? _resolveTripId(BuildContext context) {
    if (widget.tripId != null) return widget.tripId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['tripId']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsCubit, TripsState>(
      builder: (context, state) {
        if (state is TripsLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TripsError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip details')),
            body: Center(child: Text(state.message)),
          );
        }

        final trip = state is TripsLoaded ? state.selectedTrip : null;
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip details')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final canCancel = trip.status == TripStatus.upcoming;
        final canReview = trip.status == TripStatus.completed;
        final showQr =
            trip.status == TripStatus.upcoming ||
            trip.status == TripStatus.inProgress;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trip details'),
            actions: [
              if (canCancel)
                TextButton(
                  onPressed: () => showTripCancellationFlow(
                    context,
                    tripReference: trip.reference,
                  ),
                  child: Text('Cancel', style: TextStyle(color: scheme.error)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _StatusHeader(trip: trip),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Route',
                icon: Icons.route_rounded,
                child: _RouteCard(trip: trip),
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Driver',
                icon: Icons.person_rounded,
                child: _DriverCard(trip: trip),
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Vehicle',
                icon: Icons.directions_bus_filled_rounded,
                child: _VehicleCard(trip: trip),
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Seats',
                icon: Icons.event_seat_rounded,
                child: _SeatsCard(trip: trip),
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Payment status',
                icon: Icons.payments_rounded,
                child: _PaymentCard(trip: trip),
              ),
              if (showQr) ...[
                const SizedBox(height: 16),
                TripQrCard(reference: trip.reference),
              ],
              if (trip.cancellationReason != null) ...[
                const SizedBox(height: 16),
                AppSurface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: scheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancellation reason',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              trip.cancellationReason!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReview)
                    AppButton(
                      label: 'Rate this trip',
                      height: 50,
                      onPressed: () => showTripReviewFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  if (canReview &&
                      (canCancel || trip.status == TripStatus.inProgress))
                    const SizedBox(height: 10),
                  if (canCancel)
                    AppButton(
                      label: 'Cancel trip',
                      outline: true,
                      height: 50,
                      onPressed: () => showTripCancellationFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  if (trip.status == TripStatus.inProgress) ...[
                    if (canReview || canCancel) const SizedBox(height: 10),
                    AppButton(
                      label: 'Track vehicle',
                      height: 50,
                      onPressed: () {
                        Navigator.pushNamed(context, '/tracking');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.reference,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(label: trip.statusLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(trip.routeLine, style: AppTextThemes.subtitle(scheme)),
          const SizedBox(height: 6),
          Text(
            '${trip.dateLabel} · ${trip.timeLabel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(170),
            ),
          ),
          if (trip.completedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Completed ${trip.completedAt}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RoutePoint(
            icon: Icons.trip_origin_rounded,
            color: scheme.secondary,
            label: 'Pickup',
            value: trip.pickup,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 20,
                color: scheme.outline.withAlpha(100),
              ),
            ),
          ),
          _RoutePoint(
            icon: Icons.location_on_rounded,
            color: scheme.tertiary,
            label: 'Destination',
            value: trip.destination,
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppAvatar(initials: trip.driverInitials, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.driverName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      trip.driverRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' · Licensed captain',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(label: trip.vehicleType),
          const SizedBox(height: 8),
          Text(
            trip.vehicleName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'ID ${trip.vehicleId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SeatsCard extends StatelessWidget {
  const _SeatsCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: trip.seats
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(90),
                  ),
                ),
                child: Text(
                  'Seat $s',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _paymentColor(trip.paymentStatus, scheme);

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.paymentLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  trip.fare,
                  style: AppTextThemes.priceEmphasis(
                    scheme,
                  ).copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _paymentColor(PaymentStatus status, ColorScheme scheme) {
    return switch (status) {
      PaymentStatus.paid => scheme.secondary,
      PaymentStatus.pending => scheme.tertiary,
      PaymentStatus.refunded => scheme.primary,
      PaymentStatus.failed => scheme.error,
    };
  }
}
