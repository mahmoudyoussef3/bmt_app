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
                : null;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                for (final status in CaptainTripStatus.values) ...[
                  AppCard(
                    onTap: () => context.read<TripStatusUpdateCubit>().update(
                      tripId,
                      status,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(child: Text(_label(status))),
                        if (selected == status) const Icon(Icons.check_rounded),
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
}
