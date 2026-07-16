import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/trip_history_item.dart';
import '../cubit/trip_history_cubit.dart';
import '../cubit/trip_history_state.dart';
import '../utils/trip_history_filters.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  String _query = '';
  TripHistoryDateFilter _dateFilter = TripHistoryDateFilter.all;

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
            TripHistoryLoaded(:final trips) => _HistoryList(
              allTrips: trips,
              query: _query,
              dateFilter: _dateFilter,
              onQueryChanged: (value) => setState(() => _query = value),
              onDateFilterChanged: (value) =>
                  setState(() => _dateFilter = value),
            ),
          },
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.allTrips,
    required this.query,
    required this.dateFilter,
    required this.onQueryChanged,
    required this.onDateFilterChanged,
  });

  final List<TripHistoryItem> allTrips;
  final String query;
  final TripHistoryDateFilter dateFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TripHistoryDateFilter> onDateFilterChanged;

  @override
  Widget build(BuildContext context) {
    final totalPassengers = allTrips.fold<int>(0, (s, t) => s + t.boardedCount);
    final filtered = filterTripHistory(
      trips: allTrips,
      dateFilter: dateFilter,
      query: query,
    );
    final groups = groupTripHistoryByPeriod(filtered);

    return RefreshIndicator(
      onRefresh: () => context.read<TripHistoryCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          CaptainSliverHeader(
            title: 'سجل الرحلات',
            subtitle: '${allTrips.length} رحلة مكتملة',
          ),
          if (allTrips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CaptainEmptyState(
                  title: 'لا توجد رحلات مكتملة',
                  subtitle: 'ستظهر رحلاتك المنجزة هنا بعد إتمامها.',
                  icon: Icons.history_rounded,
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _SummaryRow(
                totalTrips: allTrips.length,
                totalPassengers: totalPassengers,
              ),
            ),
            SliverToBoxAdapter(
              child: _SearchAndFilterBar(
                query: query,
                dateFilter: dateFilter,
                onQueryChanged: onQueryChanged,
                onDateFilterChanged: onDateFilterChanged,
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CaptainEmptyState(
                    title: 'لا نتائج مطابقة',
                    subtitle: 'جرّب كلمة بحث مختلفة أو غيّر الفترة الزمنية.',
                    icon: Icons.search_off_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  CaptainDesignTokens.s24,
                  CaptainDesignTokens.s8,
                  CaptainDesignTokens.s24,
                  // Cleared for the shell's floating nav bar.
                  CaptainBottomNav.reservedSpace(context),
                ),
                sliver: SliverList.list(
                  children: [
                    for (final group in groups) ...[
                      _GroupLabel(label: group.label),
                      const SizedBox(height: CaptainDesignTokens.s8),
                      for (var i = 0; i < group.trips.length; i++) ...[
                        _AnimatedEntry(
                          index: i,
                          child: _TripHistoryCard(trip: group.trips[i]),
                        ),
                        const SizedBox(height: CaptainDesignTokens.s16),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.query,
    required this.dateFilter,
    required this.onQueryChanged,
    required this.onDateFilterChanged,
  });

  final String query;
  final TripHistoryDateFilter dateFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TripHistoryDateFilter> onDateFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الخط...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: CaptainColors.surfaceFor(context),
              border: OutlineInputBorder(
                borderRadius: CaptainDesignTokens.br12,
                borderSide: BorderSide(
                  color: CaptainColors.dividerFor(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in TripHistoryDateFilter.values) ...[
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: dateFilter == filter,
                    onSelected: (_) => onDateFilterChanged(filter),
                  ),
                  const SizedBox(width: CaptainDesignTokens.s8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: CaptainDesignTokens.s8),
      child: Text(
        label,
        style: CaptainTypography.titleSmall(
          context,
        ).copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// A gentle staggered fade + slide-in for list items as they first appear.
class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index.clamp(0, 8) * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.check_circle_rounded,
              color: CaptainColors.success,
              label: 'رحلات',
              value: '$totalTrips',
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s16),
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
    return CaptainCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
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
    final fullyBoarded = trip.boardingRate >= 1;

    return CaptainCard(
      padding: EdgeInsets.zero,
      onTap: () => context.openTripHistoryDetail(trip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s16,
              CaptainDesignTokens.s16,
              CaptainDesignTokens.s16,
              CaptainDesignTokens.s16,
            ),
            decoration: BoxDecoration(
              color: CaptainColors.success.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: CaptainDesignTokens.r24,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CaptainDesignTokens.s8),
                  decoration: BoxDecoration(
                    color: CaptainColors.success.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: CaptainColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: CaptainDesignTokens.s8),
                Expanded(
                  child: Text(
                    trip.route,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s8,
                    vertical: CaptainDesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: CaptainColors.success.withValues(alpha: 0.08),
                    borderRadius: CaptainDesignTokens.br8,
                    border: Border.all(
                      color: CaptainColors.success.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    'مكتملة',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CaptainColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            child: Column(
              children: [
                // Date + time row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: CaptainDesignTokens.s4),
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
                const SizedBox(height: CaptainDesignTokens.s8),
                // Stats row
                Row(
                  children: [
                    _Chip(
                      icon: Icons.people_alt_rounded,
                      label: '${trip.boardedCount}/${trip.passengerCount} راكب',
                      color: fullyBoarded
                          ? CaptainColors.success
                          : CaptainColors.warning,
                    ),
                    const SizedBox(width: CaptainDesignTokens.s8),
                    _Chip(
                      icon: Icons.timer_rounded,
                      label: durLabel,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: CaptainDesignTokens.s8),
                    if (trip.vehicleNumber.isNotEmpty)
                      _Chip(
                        icon: Icons.directions_bus_rounded,
                        label: trip.vehicleNumber,
                        color: scheme.onSurfaceVariant,
                      ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
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
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: CaptainDesignTokens.br8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: CaptainDesignTokens.s4),
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
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        children: [
          const CaptainSkeleton(height: 28, width: 140),
          const SizedBox(height: CaptainDesignTokens.s24),
          for (var i = 0; i < 5; i++) ...[
            const CaptainSkeleton(height: 120, width: double.infinity),
            const SizedBox(height: CaptainDesignTokens.s8),
          ],
        ],
      ),
    );
  }
}
