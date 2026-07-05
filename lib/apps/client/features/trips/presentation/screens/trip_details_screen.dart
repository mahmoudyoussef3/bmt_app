import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_qr_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';

/// Premium trip details screen with QR, route timeline, driver actions,
/// vehicle info, seat preview, payment summary, cancel and review flows.
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
          return const _TripLoadingView();
        }

        if (state is TripsError) {
          return _TripErrorView(message: state.message);
        }

        final trip = state is TripsLoaded ? state.selectedTrip : null;
        if (trip == null) {
          return const _TripEmptyView();
        }

        return _TripDetailsView(trip: trip);
      },
    );
  }
}

class _TripDetailsView extends StatelessWidget {
  const _TripDetailsView({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final canCancel = trip.status == TripStatus.upcoming;
    final canReview = trip.status == TripStatus.completed;
    final canTrack = trip.status == TripStatus.inProgress;
    final showQr =
        trip.status == TripStatus.upcoming ||
        trip.status == TripStatus.inProgress;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        backgroundColor: ClientColors.surfaceSubtleFor(context),
        appBar: AppBar(
          backgroundColor: ClientColors.surfaceFor(context),
          title: Text(
            'Trip Details',
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          centerTitle: false,
          actions: [
            if (canCancel)
              TextButton.icon(
                onPressed: () => showTripCancellationFlow(
                  context,
                  tripReference: trip.reference,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: ClientColors.journeyRed,
                  size: 18,
                ),
                label: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: ClientColors.journeyRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
          children: [
            _TripHeroCard(trip: trip),
            const SizedBox(height: 16),
            if (showQr) ...[
              _TripTicketCard(trip: trip),
              const SizedBox(height: 16),
            ],
            if (canTrack) ...[
              _LiveTrackingCard(trip: trip),
              const SizedBox(height: 16),
            ],
            _DetailSection(
              title: 'Route',
              subtitle: 'Pickup point and destination',
              icon: Icons.route_rounded,
              child: _RouteTimelineCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Driver',
              subtitle: 'Assigned captain details',
              icon: Icons.person_pin_circle_rounded,
              child: _DriverCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Vehicle',
              subtitle: 'Assigned vehicle details',
              icon: Icons.directions_bus_filled_rounded,
              child: _VehicleCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Seats',
              subtitle: 'Seats reserved for this trip',
              icon: Icons.event_seat_rounded,
              child: _SeatsCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Payment',
              subtitle: 'Payment status and fare',
              icon: Icons.payments_rounded,
              child: _PaymentCard(trip: trip),
            ),
            if (trip.cancellationReason != null) ...[
              const SizedBox(height: 16),
              _CancellationReasonCard(reason: trip.cancellationReason!),
            ],
            if (canReview) ...[
              const SizedBox(height: 16),
              _CompletedTripCard(trip: trip),
            ],
          ],
        ),
        bottomNavigationBar: _TripActionsBar(
          trip: trip,
          canCancel: canCancel,
          canReview: canReview,
          canTrack: canTrack,
        ),
      ),
    );
  }
}

class _TripLoadingView extends StatelessWidget {
  const _TripLoadingView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ClientColors.surfaceSubtleFor(context),
        appBar: const _StaticAppBar(title: 'Trip Details'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ClientSkeleton(height: 120, borderRadius: 20),
            const SizedBox(height: 14),
            ClientSkeleton(height: 80, borderRadius: 20),
            const SizedBox(height: 14),
            ClientSkeleton(height: 100, borderRadius: 20),
            const SizedBox(height: 14),
            ClientSkeleton(height: 90, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _TripErrorView extends StatelessWidget {
  const _TripErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ClientColors.surfaceFor(context),
        appBar: const _StaticAppBar(title: 'Trip Details'),
        body: ClientErrorCard.fullScreen(message: message),
      ),
    );
  }
}

class _TripEmptyView extends StatelessWidget {
  const _TripEmptyView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ClientColors.surfaceSubtleFor(context),
        appBar: const _StaticAppBar(title: 'Trip Details'),
        body: Center(
          child: Text(
            'Trip not found',
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ),
    );
  }
}

class _StaticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StaticAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ClientColors.surfaceFor(context),
      title: Text(title),
    );
  }
}

class _TripHeroCard extends StatelessWidget {
  const _TripHeroCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(trip.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [ClientColors.primary, Color(0xFF0D4FC4)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(55),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -36,
            end: -26,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 150,
              color: Colors.white.withAlpha(30),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroStatusChip(label: trip.statusLabel, color: statusColor),
                  const Spacer(),
                  Text(
                    trip.reference,
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: Colors.white.withAlpha(220),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                trip.routeLine,
                style: ClientTypography.headingLarge(
                  context,
                ).copyWith(color: Colors.white, height: 1.25),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroMetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: trip.dateLabel,
                  ),
                  _HeroMetaChip(
                    icon: Icons.access_time_rounded,
                    label: trip.timeLabel,
                  ),
                  _HeroMetaChip(
                    icon: Icons.event_seat_rounded,
                    label: _seatsLabel(trip),
                  ),
                ],
              ),
              if (trip.completedAt != null) ...[
                const SizedBox(height: 14),
                _HeroMetaChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Completed ${trip.completedAt}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TripStatus status) {
    return switch (status) {
      TripStatus.upcoming => ClientColors.primaryLight,
      TripStatus.inProgress => ClientColors.journeyGreenLight,
      TripStatus.completed => ClientColors.journeySlateLight,
      TripStatus.cancelled => ClientColors.journeyRedLight,
    };
  }

  String _seatsLabel(TripData trip) {
    if (trip.seats.isEmpty) return 'No seat selected';
    if (trip.seats.length == 1) return 'Seat ${trip.seats.first}';
    return '${trip.seats.length} seats';
  }
}

class _HeroStatusChip extends StatelessWidget {
  const _HeroStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTicketCard extends StatelessWidget {
  const _TripTicketCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _SoftIcon(
                icon: Icons.qr_code_2_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boarding Ticket',
                  style: ClientTypography.headingSmall(context),
                ),
              ),
              _StatusBadge(label: 'Ready', color: ClientColors.journeyGreen),
            ],
          ),
          const SizedBox(height: 14),
          TripQrCard(reference: trip.reference),
        ],
      ),
    );
  }
}

class _LiveTrackingCard extends StatelessWidget {
  const _LiveTrackingCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.primary.withAlpha(65)),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: Icons.location_searching_rounded,
            color: ClientColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your trip is in progress',
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track the vehicle location and expected arrival time.',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/tracking',
              arguments: {'bookingId': trip.id},
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: ClientColors.textInverse,
            ),
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }
}

class _CompletedTripCard extends StatelessWidget {
  const _CompletedTripCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Row(
        children: [
          _SoftIcon(icon: Icons.star_rounded, color: ClientColors.journeyAmber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Help us improve by rating your trip with ${trip.driverName}.',
              style: ClientTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TinyIcon(icon: icon, color: ClientColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTypography.headingSmall(
                      context,
                    ).copyWith(color: ClientColors.textPrimaryFor(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RouteTimelineCard extends StatelessWidget {
  const _RouteTimelineCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Column(
        children: [
          _RouteTimelinePoint(
            icon: Icons.trip_origin_rounded,
            color: ClientColors.journeyGreen,
            title: 'Pickup Point',
            value: trip.pickup,
            time: trip.timeLabel,
          ),
          _TimelineConnector(color: ClientColors.borderFor(context)),
          _RouteTimelinePoint(
            icon: Icons.location_on_rounded,
            color: ClientColors.journeyRed,
            title: 'Destination',
            value: trip.destination,
            time: 'Arrival follows the route schedule',
          ),
        ],
      ),
    );
  }
}

class _RouteTimelinePoint extends StatelessWidget {
  const _RouteTimelinePoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(34),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          width: 2,
          height: 26,
          decoration: BoxDecoration(
            color: color.withAlpha(110),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Column(
        children: [
          Row(
            children: [
              _DriverAvatar(initials: trip.driverInitials),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(color: ClientColors.textPrimaryFor(context)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: ClientColors.journeyAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.driverRating.toStringAsFixed(1),
                          style: ClientTypography.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: ClientColors.textPrimaryFor(context),
                          ),
                        ),
                        Text(
                          ' · Verified captain',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: 'Available',
                color: ClientColors.journeyGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  onTap: () => _callDriver(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  onTap: () => Navigator.pushNamed(context, '/communication'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Track',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/tracking',
                    arguments: {'bookingId': trip.id},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callDriver(BuildContext context) async {
    final phone = trip.driverPhone.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not start a call to $phone.')),
      );
    }
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: ClientColors.primaryLight,
      child: Text(
        initials,
        style: ClientTypography.headingSmall(
          context,
        ).copyWith(color: ClientColors.primary),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClientColors.primary.withAlpha(40),
                  ClientColors.primaryMuted.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: ClientColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(
                  label: trip.vehicleType,
                  color: ClientColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  trip.vehicleName,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vehicle code: ${trip.vehicleId}',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
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
    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(
                icon: Icons.event_seat_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip.seats.isEmpty ? 'No seat selected' : _selectedSeatsText,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
              ),
            ],
          ),
          if (trip.seats.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MiniSeatLayout(selectedSeats: trip.seats),
          ],
        ],
      ),
    );
  }

  String get _selectedSeatsText {
    if (trip.seats.length == 1) return 'Selected seat: ${trip.seats.first}';
    return 'Selected seats: ${trip.seats.join(', ')}';
  }
}

class _MiniSeatLayout extends StatelessWidget {
  const _MiniSeatLayout({required this.selectedSeats});

  final List<String> selectedSeats;

  @override
  Widget build(BuildContext context) {
    final seats = List.generate(_safeTotalSeats(), (index) => '${index + 1}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 34,
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.airline_seat_recline_normal_rounded,
              color: ClientColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: seats.map((seat) {
              final selected = selectedSeats.contains(seat);
              return _MiniSeatBox(number: seat, selected: selected);
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _SeatLegend(color: ClientColors.journeyGreen, label: 'Your seat'),
              _SeatLegend(
                color: ClientColors.primary.withAlpha(100),
                label: 'Other seat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _safeTotalSeats() {
    final numbers = selectedSeats.map(int.tryParse).whereType<int>().toList();
    final maxSelected = numbers.isEmpty
        ? 6
        : numbers.reduce((a, b) => a > b ? a : b);
    return maxSelected < 12 ? 12 : maxSelected;
  }
}

class _MiniSeatBox extends StatelessWidget {
  const _MiniSeatBox({required this.number, required this.selected});

  final String number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? ClientColors.journeyGreen
        : ClientColors.primary.withAlpha(92);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: ClientColors.journeyGreen.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: selected
                ? ClientColors.textInverse
                : ClientColors.textInverse,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final color = _paymentColor(trip.paymentStatus);

    return _PremiumPanel(
      child: Column(
        children: [
          Row(
            children: [
              _SoftIcon(icon: Icons.payments_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip.paymentLabel,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: color),
                ),
              ),
              _StatusBadge(
                label: _paymentLabel(trip.paymentStatus),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PaymentRow(label: 'Trip fare', value: trip.fare),
          const SizedBox(height: 8),
          const _PaymentRow(label: 'Service fee', value: '0'),
          const SizedBox(height: 8),
          const _PaymentRow(label: 'Discount', value: '0'),
          Divider(height: 24, color: ClientColors.borderFor(context)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
              ),
              Text(
                trip.fare,
                style: ClientTypography.priceHero(
                  context,
                ).copyWith(fontSize: 20, color: ClientColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _paymentColor(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => ClientColors.journeyGreen,
      PaymentStatus.pending => ClientColors.journeyAmber,
      PaymentStatus.underReview => ClientColors.journeyAmber,
      PaymentStatus.refunded => ClientColors.primary,
      PaymentStatus.failed => ClientColors.journeyRed,
    };
  }

  String _paymentLabel(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.underReview => 'Under Review',
      PaymentStatus.refunded => 'Refunded',
      PaymentStatus.failed => 'Failed',
    };
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w900,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}

class _CancellationReasonCard extends StatelessWidget {
  const _CancellationReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(
            icon: Icons.cancel_outlined,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation Reason',
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripActionsBar extends StatelessWidget {
  const _TripActionsBar({
    required this.trip,
    required this.canCancel,
    required this.canReview,
    required this.canTrack,
  });

  final TripData trip;
  final bool canCancel;
  final bool canReview;
  final bool canTrack;

  @override
  Widget build(BuildContext context) {
    if (!canCancel && !canReview && !canTrack) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context).withAlpha(245),
          border: Border(
            top: BorderSide(color: ClientColors.borderFor(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canTrack)
              ClientButton(
                label: 'Track Vehicle',
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/tracking',
                  arguments: {'bookingId': trip.id},
                ),
              ),
            if (canCancel)
              Row(
                children: [
                  Expanded(
                    child: ClientButton(
                      label: 'Track Vehicle',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/tracking',
                        arguments: {'bookingId': trip.id},
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClientButton.secondary(
                      label: 'Cancel Trip',
                      onPressed: () => showTripCancellationFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  ),
                ],
              ),
            if (canReview)
              Row(
                children: [
                  Expanded(
                    child: ClientButton(
                      label: 'Rate Trip',
                      onPressed: () => showTripReviewFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClientButton.secondary(
                      label: 'Book Again',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/booking/search'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({
    required this.child,
    this.padding = const EdgeInsets.all(
      24,
    ), // Increased padding for premium feel
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClientCard(padding: padding, useShadow: false, child: child);
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: ClientColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ClientColors.primary.withAlpha(45)),
        ),
        child: Column(
          children: [
            Icon(icon, color: ClientColors.primary, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(color: color),
      ),
    );
  }
}
