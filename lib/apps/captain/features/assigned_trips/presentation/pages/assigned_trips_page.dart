import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';

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
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AssignedTripsCubit, AssignedTripsState>(
          builder: (context, state) {
            if (state is AssignedTripsLoading) {
              return const _AssignedTripsSkeleton();
            }
            if (state is AssignedTripsError) {
              return AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: state.message,
                onRetry: () => context.read<AssignedTripsCubit>().load(),
                child: const SizedBox.shrink(),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة السائق',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'تابع رحلاتك، الركاب، والموقع من مكان واحد',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDevModeSwitcher(context),
                        child: const AppAvatar(initials: 'AM'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OverviewPanel(
                    trips: trips.length,
                    passengers: passengers,
                    boarded: boarded,
                    activeTrips: activeTrips,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'رحلات اليوم',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${trips.length} رحلة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (trips.isEmpty)
                    EmptyState(
                      title: 'لا توجد رحلات معينة اليوم',
                      subtitle:
                          'عند تعيين رحلة لك من العمليات ستظهر هنا مباشرة.',
                    )
                  else
                    for (final trip in trips) ...[
                      AssignedTripCard(
                        trip: trip,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TripExecutionPage(trip: trip),
                          ),
                        ),
                        onManifest: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PassengerListPage(tripId: trip.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            );
          },
        ),
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
    return AppCard(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 10),
              _Metric(
                label: 'نشطة',
                value: activeTrips.toString(),
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: 10),
              _Metric(
                label: 'الركاب',
                value: passengers.toString(),
                icon: Icons.people_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'صعد $boarded من $passengers راكب',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(progress: progress),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withAlpha(70)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        const SkeletonBox(height: 28, width: 150),
        const SizedBox(height: 10),
        const SkeletonBox(height: 14, width: 240),
        const SizedBox(height: 20),
        SkeletonBox(height: 150, borderRadius: BorderRadius.circular(18)),
        const SizedBox(height: 20),
        const SkeletonBox(height: 22, width: 110),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          SkeletonBox(height: 178, borderRadius: BorderRadius.circular(18)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
