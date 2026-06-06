import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/check_in/presentation/pages/check_in_page.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chats_page.dart';
import 'package:bmt_app/apps/captain/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/pages/live_location_page.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/presentation/pages/status_update_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';

class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripExecutionCubit>(
      create: (_) => captainGetIt<TripExecutionCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Trip Execution')),
        body: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
          builder: (context, state) {
            final status = state is TripExecutionIdle
                ? state.status
                : TripExecutionStatus.scheduled;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.route,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vehicle ${trip.vehicleNumber} • ${trip.plateNumber}',
                      ),
                      const SizedBox(height: 12),
                      StatusChip(label: _statusLabel(status)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Start Trip',
                              onPressed: () {
                                if (status == TripExecutionStatus.completed) {
                                  return;
                                }
                                context.read<TripExecutionCubit>().start(
                                  trip.id,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'End Trip',
                              outline: true,
                              onPressed: () {
                                if (status == TripExecutionStatus.completed) {
                                  return;
                                }
                                context.read<TripExecutionCubit>().complete(
                                  trip.id,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  label: 'Passenger Manifest',
                  icon: Icons.people_alt_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PassengerListPage(tripId: trip.id),
                    ),
                  ),
                ),
                _ActionTile(
                  label: 'Check-In',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckInPage(tripId: trip.id),
                    ),
                  ),
                ),
                _ActionTile(
                  label: 'Live Location',
                  icon: Icons.location_on_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveLocationPage(tripId: trip.id),
                    ),
                  ),
                ),
                _ActionTile(
                  label: 'Communication',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatsPage(tripId: trip.id),
                    ),
                  ),
                ),
                _ActionTile(
                  label: 'Status Updates',
                  icon: Icons.sync_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StatusUpdatePage(tripId: trip.id),
                    ),
                  ),
                ),
                _ActionTile(
                  label: 'Report Incident',
                  icon: Icons.report_problem_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportIncidentPage(tripId: trip.id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled => 'Scheduled',
      TripExecutionStatus.inProgress => 'In Progress',
      TripExecutionStatus.completed => 'Completed',
    };
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
