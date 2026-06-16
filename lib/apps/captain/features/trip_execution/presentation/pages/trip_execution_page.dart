import 'dart:async';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/check_in/presentation/pages/check_in_page.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chats_page.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
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
      child: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
        builder: (context, state) {
          final status = state is TripExecutionIdle
              ? state.status
              : TripExecutionStatus.scheduled;
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Execution')),
            floatingActionButton: status == TripExecutionStatus.inProgress
                ? _SosButton(tripId: trip.id)
                : null,
            body: ListView(
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
                      if (state is TripExecutionLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: _actionButton(context, status),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (status == TripExecutionStatus.inProgress && trip.stops.isNotEmpty)
                  _NextStopBanner(stops: trip.stops),
                if (status == TripExecutionStatus.inProgress && trip.stops.isNotEmpty)
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
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled  => 'Scheduled',
      TripExecutionStatus.boarding   => 'Boarding',
      TripExecutionStatus.inProgress => 'In Progress',
      TripExecutionStatus.completed  => 'Completed',
      TripExecutionStatus.cancelled  => 'Cancelled',
    };
  }

  Widget _actionButton(BuildContext context, TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled => AppButton(
        label: 'Start Boarding',
        onPressed: () => context.read<TripExecutionCubit>().board(trip.id),
      ),
      TripExecutionStatus.boarding => AppButton(
        label: 'Start Trip',
        onPressed: () => context.read<TripExecutionCubit>().start(trip.id),
      ),
      TripExecutionStatus.inProgress => AppButton(
        label: 'End Trip',
        outline: true,
        onPressed: () => context.read<TripExecutionCubit>().complete(trip.id),
      ),
      TripExecutionStatus.completed || TripExecutionStatus.cancelled => AppButton(
        label: _statusLabel(status),
        onPressed: () {},
      ),
    };
  }
}

class _SosButton extends StatefulWidget {
  const _SosButton({required this.tripId});
  final String tripId;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  Timer? _holdTimer;
  double _progress = 0;
  Timer? _progressTimer;

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _progress = 0);
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _progress += 50 / 3000);
      if (_progress >= 1) {
        _cancel();
        _triggerSos();
      }
    });
  }

  void _cancel() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  void _triggerSos() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportIncidentPage(
          tripId: widget.tripId,
          initialType: IncidentType.emergency,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: (_) => _cancel(),
      onLongPressCancel: _cancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_progress > 0)
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 4,
                color: Colors.red,
                backgroundColor: Colors.red.withAlpha(60),
              ),
            ),
          FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hold for 3 seconds to send SOS'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'SOS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStopBanner extends StatefulWidget {
  const _NextStopBanner({required this.stops});
  final List<String> stops;

  @override
  State<_NextStopBanner> createState() => _NextStopBannerState();
}

class _NextStopBannerState extends State<_NextStopBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.stops.length - _currentIndex;
    final isLast = _currentIndex >= widget.stops.length;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                isLast ? 'Final Destination Reached' : 'Next Stop',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary),
              ),
              const Spacer(),
              if (!isLast)
                Text(
                  '$remaining stop${remaining > 1 ? 's' : ''} remaining',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 6),
            Text(
              widget.stops[_currentIndex],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentIndex++),
                child: const Text('Mark Arrived'),
              ),
            ),
          ],
        ],
      ),
    );
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
