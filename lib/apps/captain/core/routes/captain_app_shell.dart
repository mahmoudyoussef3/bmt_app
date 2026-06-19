import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/assigned_trips/presentation/pages/assigned_trips_page.dart';
import '../../features/communication/presentation/cubit/captain_notification_cubit.dart';
import '../di/captain_di.dart';

class CaptainAppShell extends StatelessWidget {
  const CaptainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssignedTripsCubit>(
          create: (_) => captainGetIt<AssignedTripsCubit>(),
        ),
        BlocProvider<CaptainNotificationCubit>(
          create: (_) =>
              captainGetIt<CaptainNotificationCubit>()..startListening(),
        ),
      ],
      child: BlocListener<CaptainNotificationCubit, CaptainNotificationState>(
        listener: (context, state) {
          if (state is CaptainNotificationReceived) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('رسالة من العمليات: ${state.message}'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'إغلاق',
                  textColor: Colors.white,
                  onPressed: () => context
                      .read<CaptainNotificationCubit>()
                      .clearNotification(),
                ),
              ),
            );
            context.read<CaptainNotificationCubit>().clearNotification();
          }
        },
        child: const AssignedTripsPage(),
      ),
    );
  }
}
