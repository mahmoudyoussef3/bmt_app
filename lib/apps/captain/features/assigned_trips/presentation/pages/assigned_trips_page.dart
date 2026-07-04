import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_spacing.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';

import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';

import '../../domain/entities/assigned_trip.dart';
import '../cubit/assigned_trips_cubit.dart';
import '../cubit/assigned_trips_state.dart';
import '../widgets/assigned_trip_card.dart';

class AssignedTripsPage extends StatefulWidget {
  const AssignedTripsPage({super.key});

  @override
  State<AssignedTripsPage> createState() => _AssignedTripsPageState();
}

class _AssignedTripsPageState extends State<AssignedTripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssignedTripsCubit>().load();
  }

  void _showDevModeSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<AppModeCubit, AppModeState>(
            builder: (context, state) {
              final cubit = context.read<AppModeCubit>();
              final current = state.mode;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات المطور',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تغيير وضع التطبيق (للتطوير فقط)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppMode.values.map((m) {
                      final active = m == current;
                      return FilterChip(
                        label: Text(m.displayLabel),
                        selected: active,
                        onSelected: (_) {
                          if (!active) {
                            cubit.changeMode(m);
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocBuilder<AssignedTripsCubit, AssignedTripsState>(
        builder: (context, state) {
          if (state is AssignedTripsLoading) {
            return const _AssignedTripsSkeleton();
          }
          if (state is AssignedTripsError) {
            return SafeArea(
              child: AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: state.message,
                onRetry: () => context.read<AssignedTripsCubit>().load(),
                child: const SizedBox.shrink(),
              ),
            );
          }

          final List<AssignedTrip> trips = state is AssignedTripsLoaded
              ? state.trips
              : const <AssignedTrip>[];

          final boarded = trips.fold<int>(
            0,
            (total, trip) => total + trip.boardedCount,
          );
          final passengers = trips.fold<int>(
            0,
            (total, trip) => total + trip.passengerCount,
          );
          final activeTrips = trips
              .where(
                (trip) =>
                    trip.status == AssignedTripStatus.boarding ||
                    trip.status == AssignedTripStatus.inProgress,
              )
              .length;

          return RefreshIndicator(
            onRefresh: () => context.read<AssignedTripsCubit>().refresh(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: scheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(color: scheme.surface),
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: CaptainSpacing.xl,
                      vertical: CaptainSpacing.lg,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة القيادة',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showDevModeSwitcher(context),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.surfaceContainerHighest,
                            ),
                            child: const AppAvatar(initials: 'ك'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CaptainSpacing.xl,
                      CaptainSpacing.md,
                      CaptainSpacing.xl,
                      CaptainSpacing.xl,
                    ),
                    child: _OverviewPanel(
                      trips: trips.length,
                      passengers: passengers,
                      boarded: boarded,
                      activeTrips: activeTrips,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'رحلات اليوم',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CaptainSpacing.md,
                            vertical: CaptainSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(20),
                            borderRadius: CaptainRadius.rPill,
                          ),
                          child: Text(
                            '${trips.length} رحلات',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
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
                      child: CaptainEmptyState(
                        title: 'لا توجد رحلات اليوم',
                        subtitle:
                            'ستظهر رحلاتك هنا عند تعيينها من قبل العمليات.',
                        icon: Icons.route_outlined,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      CaptainSpacing.xl,
                      CaptainSpacing.lg,
                      CaptainSpacing.xl,
                      CaptainSpacing.xxxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final trip = trips[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: CaptainSpacing.lg,
                          ),
                          child: AssignedTripCard(
                            trip: trip,
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TripExecutionPage(trip: trip),
                              ),
                            ),
                            onManifest: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PassengerListPage(tripId: trip.id),
                              ),
                            ),
                          ),
                        );
                      }, childCount: trips.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.trips,
    required this.passengers,
    required this.boarded,
    required this.activeTrips,
  });

  final int trips;
  final int passengers;
  final int boarded;
  final int activeTrips;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = passengers == 0 ? 0.0 : boarded / passengers;

    return CaptainCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(CaptainSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Metric(
                label: 'الرحلات',
                value: trips.toString(),
                icon: Icons.route_rounded,
              ),
              const SizedBox(width: CaptainSpacing.md),
              _Metric(
                label: 'نشطة',
                value: activeTrips.toString(),
                icon: Icons.bolt_rounded,
                isHighlight: activeTrips > 0,
              ),
              const SizedBox(width: CaptainSpacing.md),
              _Metric(
                label: 'الركاب',
                value: passengers.toString(),
                icon: Icons.people_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: CaptainSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدم الصعود',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainSpacing.md),
          ClipRRect(
            borderRadius: CaptainRadius.rSm,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(height: CaptainSpacing.sm),
          Text(
            'صعد $boarded من أصل $passengers راكب',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isHighlight ? Colors.orange : scheme.primary;
    final bgColor = isHighlight
        ? Colors.orange.withAlpha(20)
        : scheme.surfaceContainerHighest;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: CaptainSpacing.lg,
          horizontal: CaptainSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: CaptainRadius.rLg,
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: CaptainSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: CaptainSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedTripsSkeleton extends StatelessWidget {
  const _AssignedTripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CaptainSpacing.xl),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CaptainSkeleton(height: 32, width: 140),
              CaptainSkeleton(
                height: 40,
                width: 40,
                borderRadius: CaptainRadius.rPill,
              ),
            ],
          ),
          const SizedBox(height: CaptainSpacing.xl),
          const CaptainSkeleton(height: 18, width: double.infinity),
          const SizedBox(height: CaptainSpacing.md),
          const CaptainSkeleton(height: 16, width: double.infinity),
          const SizedBox(height: CaptainSpacing.lg),
          Row(
            children: [
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
              const SizedBox(width: CaptainSpacing.md),
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
            ],
          ),
          const SizedBox(height: CaptainSpacing.xxl),
          const CaptainSkeleton(height: 24, width: 120),
          const SizedBox(height: CaptainSpacing.lg),
          for (var i = 0; i < 3; i++) ...[
            CaptainSkeleton(
              height: 220,
              borderRadius: CaptainRadius.rXl,
              width: double.infinity,
            ),
            const SizedBox(height: CaptainSpacing.xl),
          ],
        ],
      ),
    );
  }
}
