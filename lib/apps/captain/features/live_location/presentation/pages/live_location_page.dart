import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/live_location_cubit.dart';
import '../cubit/live_location_state.dart';

class LiveLocationPage extends StatelessWidget {
  const LiveLocationPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveLocationCubit>(
      create: (_) => captainGetIt<LiveLocationCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Live Location')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<LiveLocationCubit, LiveLocationState>(
            builder: (context, state) {
              final enabled = state is LiveLocationReady && state.enabled;
              return AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'Sharing location' : 'Location sharing off',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current trip: $tripId',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: enabled ? 'Stop Sharing' : 'Start Sharing',
                      onPressed: () {
                        final cubit = context.read<LiveLocationCubit>();
                        enabled ? cubit.stop(tripId) : cubit.start(tripId);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
