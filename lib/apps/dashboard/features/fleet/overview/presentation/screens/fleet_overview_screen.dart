import 'package:bmt_app/apps/dashboard/features/fleet/presentation/screens/fleet_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/empty_state.dart';
import '../cubit/fleet_overview_cubit.dart';
import '../cubit/fleet_overview_state.dart';

class FleetOverviewScreen extends StatelessWidget {
  const FleetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetOverviewCubit, FleetOverviewState>(
      builder: (context, state) {
        if (state is FleetOverviewLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FleetOverviewError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is FleetOverviewLoaded) {
          return BlocProvider(
            create: (_) => dashboardDi<FleetCubit>()..load(),
            child: const FleetScreen(),
          );
        }

        return const EmptyState(
          emoji: '🚛',
          title: 'Fleet Management',
          subtitle: 'Loading workspace...',
        );
      },
    );
  }
}
