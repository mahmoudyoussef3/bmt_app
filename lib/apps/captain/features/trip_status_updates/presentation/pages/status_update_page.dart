import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_trip_status.dart';
import '../cubit/trip_status_update_cubit.dart';
import '../cubit/trip_status_update_state.dart';

class StatusUpdatePage extends StatelessWidget {
  const StatusUpdatePage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripStatusUpdateCubit>(
      create: (_) => captainGetIt<TripStatusUpdateCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('تحديث حالة الرحلة')),
        body: BlocBuilder<TripStatusUpdateCubit, TripStatusUpdateState>(
          builder: (context, state) {
            final selected = state is TripStatusUpdateReady
                ? state.status
                : state is TripStatusUpdateLoading
                ? state.status
                : state is TripStatusUpdateError
                ? state.status
                : null;
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 20),
              children: [
                if (state is TripStatusUpdateError) ...[
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final status in CaptainTripStatus.values) ...[
                  AppCard(
                    onTap: state is TripStatusUpdateLoading
                        ? null
                        : () => context.read<TripStatusUpdateCubit>().update(
                            tripId,
                            status,
                          ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(_icon(status), color: _color(status)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _label(status),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (state is TripStatusUpdateLoading &&
                            selected == status)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (selected == status)
                          const Icon(Icons.check_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _label(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup => 'في الطريق إلى نقطة الانطلاق',
      CaptainTripStatus.arrivedPickup => 'وصل إلى نقطة الانطلاق',
      CaptainTripStatus.boarding => 'صعود الركاب',
      CaptainTripStatus.departed => 'انطلق',
      CaptainTripStatus.arrivedDestination => 'وصل إلى الوجهة',
      CaptainTripStatus.completed => 'مكتمل',
    };
  }

  IconData _icon(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup => Icons.near_me_rounded,
      CaptainTripStatus.arrivedPickup => Icons.pin_drop_rounded,
      CaptainTripStatus.boarding => Icons.groups_rounded,
      CaptainTripStatus.departed => Icons.directions_bus_rounded,
      CaptainTripStatus.arrivedDestination => Icons.flag_rounded,
      CaptainTripStatus.completed => Icons.check_circle_rounded,
    };
  }

  Color _color(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup => Colors.blue,
      CaptainTripStatus.arrivedPickup => Colors.teal,
      CaptainTripStatus.boarding => Colors.orange,
      CaptainTripStatus.departed => Colors.green,
      CaptainTripStatus.arrivedDestination => Colors.indigo,
      CaptainTripStatus.completed => Colors.grey,
    };
  }
}
