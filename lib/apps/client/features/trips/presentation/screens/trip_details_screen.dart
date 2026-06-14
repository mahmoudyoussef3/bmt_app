
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
        trip.status == TripStatus.upcoming || trip.status == TripStatus.inProgress;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('تفاصيل الرحلة'),
          centerTitle: false,
          actions: [
            if (canCancel)
              TextButton.icon(
                onPressed: () => showTripCancellationFlow(
                  context,
                  tripReference: trip.reference,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                label: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
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
              title: 'خط السير',
              subtitle: 'نقطة الركوب والوجهة',
              icon: Icons.route_rounded,
              child: _RouteTimelineCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'السائق',
              subtitle: 'بيانات الكابتن المسؤول عن الرحلة',
              icon: Icons.person_pin_circle_rounded,
              child: _DriverCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'العربية',
              subtitle: 'بيانات المركبة المخصصة للرحلة',
              icon: Icons.directions_bus_filled_rounded,
              child: _VehicleCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'المقاعد',
              subtitle: 'المقاعد المحجوزة في هذه الرحلة',
              icon: Icons.event_seat_rounded,
              child: _SeatsCard(trip: trip),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'الدفع',
              subtitle: 'حالة الدفع وقيمة الرحلة',
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
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: _StaticAppBar(title: 'تفاصيل الرحلة'),
        body: Center(child: CircularProgressIndicator()),
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
        appBar: const _StaticAppBar(title: 'تفاصيل الرحلة'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حدث خطأ أثناء تحميل الرحلة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripEmptyView extends StatelessWidget {
  const _TripEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: _StaticAppBar(title: 'تفاصيل الرحلة'),
        body: Center(child: Text('لم يتم العثور على الرحلة')),
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
    return AppBar(title: Text(title));
  }
}

class _TripHeroCard extends StatelessWidget {
  const _TripHeroCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(trip.status, scheme);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [scheme.primary, scheme.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(55),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
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
                  label: 'تمت الرحلة ${trip.completedAt}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TripStatus status, ColorScheme scheme) {
    return switch (status) {
      TripStatus.upcoming => scheme.primary,
      TripStatus.inProgress => scheme.secondary,
      TripStatus.completed => scheme.tertiary,
      TripStatus.cancelled => scheme.error,
    };
  }

  String _seatsLabel(TripData trip) {
    if (trip.seats.isEmpty) return 'لا يوجد مقعد محدد';
    if (trip.seats.length == 1) return 'مقعد ${trip.seats.first}';
    return '${trip.seats.length} مقاعد';
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تذكرة الركوب',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              StatusChip(label: 'جاهزة'),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondary.withAlpha(22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.secondary.withAlpha(65)),
      ),
      child: Row(
        children: [
          _SoftIcon(icon: Icons.location_searching_rounded, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرحلة بدأت بالفعل',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تابع مكان العربية ووقت الوصول المتوقع.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/tracking'),
            child: const Text('تتبع'),
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
          _SoftIcon(
            icon: Icons.star_rounded,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ساعدنا نحسن الخدمة بتقييم رحلتك مع ${trip.driverName}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TinyIcon(icon: icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
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
    final scheme = Theme.of(context).colorScheme;

    return _PremiumPanel(
      child: Column(
        children: [
          _RouteTimelinePoint(
            icon: Icons.trip_origin_rounded,
            color: scheme.secondary,
            title: 'نقطة الركوب',
            value: trip.pickup,
            time: trip.timeLabel,
          ),
          _TimelineConnector(color: scheme.outline),
          _RouteTimelinePoint(
            icon: Icons.location_on_rounded,
            color: scheme.tertiary,
            title: 'الوجهة',
            value: trip.destination,
            time: 'الوصول حسب خط الرحلة',
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
    final scheme = Theme.of(context).colorScheme;

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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(145),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
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
    final scheme = Theme.of(context).colorScheme;

    return _PremiumPanel(
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(initials: trip.driverInitials, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 17, color: scheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          trip.driverRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          ' · كابتن معتمد',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(145),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(label: 'متاح'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.call_rounded,
                  label: 'اتصال',
                  onTap: () => _showComingSoon(context, 'الاتصال بالسائق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'محادثة',
                  onTap: () => _showComingSoon(context, 'محادثة السائق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'تتبع',
                  onTap: () => Navigator.pushNamed(context, '/tracking'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature سيتم تفعيله قريبًا')),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PremiumPanel(
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withAlpha(40),
                  scheme.secondary.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: scheme.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(label: trip.vehicleType),
                const SizedBox(height: 8),
                Text(
                  trip.vehicleName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كود العربية: ${trip.vehicleId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(145),
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

class _SeatsCard extends StatelessWidget {
  const _SeatsCard({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(icon: Icons.event_seat_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip.seats.isEmpty ? 'لا يوجد مقعد محدد' : _selectedSeatsText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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
    if (trip.seats.length == 1) return 'مقعدك المختار: ${trip.seats.first}';
    return 'مقاعدك المختارة: ${trip.seats.join(', ')}';
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(90),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.airline_seat_recline_normal_rounded,
              color: Theme.of(context).colorScheme.primary,
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
              _SeatLegend(
                color: Theme.of(context).colorScheme.tertiary,
                label: 'مقعدك',
              ),
              _SeatLegend(
                color: Theme.of(context).colorScheme.primary.withAlpha(100),
                label: 'مقعد آخر',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _safeTotalSeats() {
    final numbers = selectedSeats.map(int.tryParse).whereType<int>().toList();
    final maxSelected = numbers.isEmpty ? 6 : numbers.reduce((a, b) => a > b ? a : b);
    return maxSelected < 12 ? 12 : maxSelected;
  }
}

class _MiniSeatBox extends StatelessWidget {
  const _MiniSeatBox({required this.number, required this.selected});

  final String number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.tertiary : scheme.primary.withAlpha(92);

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
                  color: scheme.tertiary.withAlpha(60),
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
            color: selected ? scheme.onTertiary : Colors.white,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
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
    final scheme = Theme.of(context).colorScheme;
    final color = _paymentColor(trip.paymentStatus, scheme);

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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                ),
              ),
              StatusChip(label: _paymentArabicLabel(trip.paymentStatus)),
            ],
          ),
          const SizedBox(height: 16),
          _PaymentRow(label: 'سعر الرحلة', value: trip.fare),
          const SizedBox(height: 8),
          const _PaymentRow(label: 'رسوم الخدمة', value: '0'),
          const SizedBox(height: 8),
          const _PaymentRow(label: 'الخصم', value: '0'),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الإجمالي',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                trip.fare,
                style: AppTextThemes.priceEmphasis(scheme).copyWith(fontSize: 20),
              ),
            ],
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

  String _paymentArabicLabel(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => 'مدفوع',
      PaymentStatus.pending => 'قيد الانتظار',
      PaymentStatus.refunded => 'مسترد',
      PaymentStatus.failed => 'فشل',
    };
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(155),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
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
    final scheme = Theme.of(context).colorScheme;

    return _PremiumPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(icon: Icons.cancel_outlined, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سبب الإلغاء',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
          color: Theme.of(context).scaffoldBackgroundColor.withAlpha(245),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(80),
            ),
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
              AppButton(
                label: 'تتبع العربية',
                height: 52,
                onPressed: () => Navigator.pushNamed(context, '/tracking'),
              ),
            if (canCancel)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'تتبع العربية',
                      height: 52,
                      onPressed: () => Navigator.pushNamed(context, '/tracking'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'إلغاء الرحلة',
                      outline: true,
                      height: 52,
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
                    child: AppButton(
                      label: 'تقييم الرحلة',
                      height: 52,
                      onPressed: () => showTripReviewFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'احجز مرة أخرى',
                      outline: true,
                      height: 52,
                      onPressed: () => Navigator.pushNamed(context, '/booking'),
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
  const _PremiumPanel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outline.withAlpha(70)),
        ),
        child: child,
      ),
    );
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withAlpha(45)),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
