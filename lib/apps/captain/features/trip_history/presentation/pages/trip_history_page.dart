import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/trip_history_item.dart';
import '../cubit/trip_history_cubit.dart';
import '../cubit/trip_history_state.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<TripHistoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<TripHistoryCubit, TripHistoryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          body: switch (state) {
            TripHistoryLoading() => const _HistorySkeleton(),
            TripHistoryError(:final message) => SafeArea(
                child: AsyncStateView(
                  status: AsyncViewStatus.error,
                  errorMessage: message,
                  onRetry: () => context.read<TripHistoryCubit>().load(),
                  child: const SizedBox.shrink(),
                ),
              ),
            TripHistoryLoaded(:final trips) => _HistoryList(trips: trips),
          },
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.trips});

  final List<TripHistoryItem> trips;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalPassengers = trips.fold<int>(0, (s, t) => s + t.boardedCount);

    return RefreshIndicator(
      onRefresh: () => context.read<TripHistoryCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: scheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل الرحلات',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  Text(
                    '${trips.length} رحلة مكتملة',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (trips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  title: 'لا توجد رحلات مكتملة',
                  subtitle: 'ستظهر رحلاتك المنجزة هنا بعد إتمامها.',
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _SummaryRow(
                totalTrips: trips.length,
                totalPassengers: totalPassengers,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.builder(
                itemCount: trips.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TripHistoryCard(trip: trips[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.totalTrips, required this.totalPassengers});

  final int totalTrips;
  final int totalPassengers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              label: 'رحلات',
              value: '$totalTrips',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryTile(
              icon: Icons.people_alt_rounded,
              color: scheme.primary,
              label: 'ركاب نُقلوا',
              value: '$totalPassengers',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      )),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEEE، d MMMM y', 'ar').format(trip.tripDate);
    final departure = _fmt(trip.departureTime);
    final arrival = _fmt(trip.arrivalTime);
    final dur = trip.duration;
    final durLabel = dur.inMinutes > 0
        ? '${dur.inHours > 0 ? '${dur.inHours}س ' : ''}${dur.inMinutes.remainder(60)}د'
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withAlpha(8), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trip.route,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withAlpha(60)),
                  ),
                  child: Text(
                    'مكتملة',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.green, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date + time row
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Text(
                      '$departure → $arrival',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    _Chip(
                      icon: Icons.people_alt_rounded,
                      label: '${trip.boardedCount}/${trip.passengerCount} راكب',
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.timer_rounded,
                      label: durLabel,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    if (trip.vehicleNumber.isNotEmpty)
                      _Chip(
                        icon: Icons.directions_bus_rounded,
                        label: trip.vehicleNumber,
                        color: scheme.onSurfaceVariant,
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

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonBox(height: 28, width: 140),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            SkeletonBox(height: 120, borderRadius: BorderRadius.circular(20)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
