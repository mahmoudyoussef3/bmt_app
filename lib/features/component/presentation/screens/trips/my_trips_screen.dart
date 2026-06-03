import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_mock_data.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_routes.dart';
import 'package:bmt_app/features/component/presentation/widgets/trips/trip_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/trips/trip_filter_bar.dart';

/// My Trips hub with filter tabs for upcoming, active, completed, cancelled.
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  TripFilter _filter = TripFilter.upcoming;

  Map<TripFilter, int> get _counts => {
    for (final f in TripFilter.values) f: countForFilter(f),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trips = tripsForFilter(_filter);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 900 ? 720.0 : (width >= 600 ? 560.0 : width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _TripsHeader(
                  scheme: scheme,
                  onBookTrip: () => widget.onOpenRoute(BookingRoutes.search),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TripFilterBar(
                  selected: _filter,
                  counts: _counts,
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SectionTitle(filter: _filter, count: trips.length),
              ),
            ),
            if (trips.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _TripsEmptyState(filter: _filter),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final trip = trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TripCard(
                        trip: trip,
                        onTap: () => widget.onOpenRoute(
                          TripsRoutes.tripDetails,
                          {'tripId': trip.id},
                        ),
                      ),
                    );
                  }, childCount: trips.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader({required this.scheme, required this.onBookTrip});

  final ColorScheme scheme;
  final VoidCallback onBookTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(70),
            scheme.secondary.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Trips',
                      style: AppTextThemes.headlineStrong(scheme),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upcoming, active, and past commutes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(190),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onBookTrip,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Book new trip',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Upcoming',
                  value: '${countForFilter(TripFilter.upcoming)}',
                  icon: Icons.upcoming_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Active',
                  value: '${countForFilter(TripFilter.active)}',
                  icon: Icons.directions_bus_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.filter, required this.count});

  final TripFilter filter;
  final int count;

  String get _title {
    switch (filter) {
      case TripFilter.upcoming:
        return 'Upcoming trips';
      case TripFilter.active:
        return 'In progress trips';
      case TripFilter.completed:
        return 'Completed trips';
      case TripFilter.cancelled:
        return 'Cancelled trips';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _title,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TripsEmptyState extends StatelessWidget {
  const _TripsEmptyState({required this.filter});

  final TripFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = switch (filter) {
      TripFilter.upcoming => 'No upcoming trips scheduled',
      TripFilter.active => 'No trips in progress right now',
      TripFilter.completed => 'No completed trips yet',
      TripFilter.cancelled => 'No cancelled trips',
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: scheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
