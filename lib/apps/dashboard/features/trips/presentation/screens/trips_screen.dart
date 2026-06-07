import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_trip.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../widgets/trip_details_panel.dart';
import '../widgets/trips_kanban_board.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsCubit, TripsState>(
      builder: (context, state) {
        return switch (state) {
          TripsLoading() => const Center(child: CircularProgressIndicator()),
          TripsError(:final message) => _TripsError(message: message),
          TripsLoaded() => _TripsLoadedView(state: state),
        };
      },
    );
  }
}

class _TripsLoadedView extends StatelessWidget {
  final TripsLoaded state;

  const _TripsLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsCubit>();
    final selected = state.selectedTrip;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel = selected != null && constraints.maxWidth >= 1180;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.large),
                children: [
                  _TripsHeader(totalTrips: state.trips.length),
                  const SizedBox(height: AppSpacing.large),
                  TripsKanbanBoard(
                    trips: state.trips,
                    onTripSelected: (trip) {
                      if (constraints.maxWidth < 1180) {
                        _openDetailsSheet(context, trip);
                      } else {
                        cubit.showDetails(trip);
                      }
                    },
                    onTripMoved: cubit.moveTrip,
                  ),
                ],
              ),
            ),
            if (showSidePanel) ...[
              const SizedBox(width: AppSpacing.medium),
              SizedBox(
                width: 440,
                child: TripDetailsPanel(
                  trip: selected,
                  onClose: cubit.closeDetails,
                  onStatusChanged: (status) => cubit.moveTrip(selected, status),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TripsHeader extends StatelessWidget {
  final int totalTrips;

  const _TripsHeader({required this.totalTrips});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.view_kanban_outlined, size: 42),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز تشغيل الرحلات',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'لوحة Kanban لتحريك الرحلات بين حالات التشغيل اليومية.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text('$totalTrips رحلة'),
        ],
      ),
    );
  }
}

class _TripsError extends StatelessWidget {
  final String message;

  const _TripsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

void _openDetailsSheet(BuildContext context, OperationTrip trip) {
  final cubit = context.read<TripsCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: TripDetailsPanel(
            trip: trip,
            onClose: Navigator.of(context).pop,
            onStatusChanged: (status) => cubit.moveTrip(trip, status),
          ),
        ),
      ),
    ),
  );
}
