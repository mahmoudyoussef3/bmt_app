import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/assigned_trips/presentation/pages/assigned_trips_page.dart';
import '../di/captain_di.dart';

class CaptainAppShell extends StatelessWidget {
  const CaptainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignedTripsCubit>(
      create: (_) => captainGetIt<AssignedTripsCubit>(),
      child: const AssignedTripsPage(),
    );
  }
}
