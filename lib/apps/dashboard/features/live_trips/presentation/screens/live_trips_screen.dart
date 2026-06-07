import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/live_trips_cubit.dart';
import '../cubit/live_trips_state.dart';
import '../widgets/live_monitoring_panel.dart';
import '../widgets/live_trip_card.dart';

class LiveTripsScreen extends StatelessWidget {
  const LiveTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTripsCubit, LiveTripsState>(
      builder: (context, state) {
        return switch (state) {
          LiveTripsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          LiveTripsError(:final message) => Center(child: Text(message)),
          LiveTripsLoaded() => _LiveTripsLoadedView(state: state),
        };
      },
    );
  }
}

class _LiveTripsLoadedView extends StatelessWidget {
  final LiveTripsLoaded state;

  const _LiveTripsLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveTripsCubit>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.radar_outlined, size: 42),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مركز مراقبة الرحلات المباشرة',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        'متابعة حية للرحلات النشطة والتنبيهات التشغيلية.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Badge(
                  label: Text('${state.urgentAlertsCount}'),
                  isLabelVisible: state.urgentAlertsCount > 0,
                  child: const Icon(Icons.warning_amber_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 980;
                final tripList = _ActiveTripsList(
                  state: state,
                  onSelected: cubit.selectTrip,
                );
                final panel = LiveMonitoringPanel(trip: state.selectedTrip);

                if (compact) {
                  return ListView(
                    children: [
                      tripList,
                      const SizedBox(height: AppSpacing.medium),
                      SizedBox(height: 900, child: panel),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 390, child: tripList),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: panel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripsList extends StatelessWidget {
  final LiveTripsLoaded state;
  final ValueChanged<String> onSelected;

  const _ActiveTripsList({required this.state, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Trips', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...state.trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: LiveTripCard(
                trip: trip,
                selected: trip.id == state.selectedTripId,
                onTap: () => onSelected(trip.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
