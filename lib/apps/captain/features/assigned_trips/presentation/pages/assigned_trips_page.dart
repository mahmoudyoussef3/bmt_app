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
                    'Developer Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Switch application mode (development only)',
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
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AssignedTripsError) {
              return Center(child: Text(state.message));
            }
            final List<AssignedTrip> trips = state is AssignedTripsLoaded
                ? state.trips
                : const <AssignedTrip>[];
            return RefreshIndicator(
              onRefresh: () => context.read<AssignedTripsCubit>().refresh(),
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Captain Workspace',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Assigned trips only',
                            style: Theme.of(context).textTheme.bodySmall,
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
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Trips',
                          value: trips.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          label: 'Passengers',
                          value: trips
                              .fold<int>(
                                0,
                                (int total, trip) =>
                                    total + trip.passengerCount,
                              )
                              .toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Today', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
