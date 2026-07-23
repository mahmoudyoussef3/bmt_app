import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_trip_status.dart';
import '../cubit/trip_status_update_cubit.dart';
import '../cubit/trip_status_update_state.dart';

/// Posts a progress note to operations. **Not** a lifecycle control.
///
/// Every option here writes one narrative row to `trip_events`; none of them
/// touches `operation_trips.status`. The trip's real stage is moved only by the
/// docked action bar on the execution screen, through
/// `captain_update_trip_status`.
///
/// That distinction used to be invisible. The page was titled "تحديث حالة
/// الرحلة" — update the trip's status — and offered "مكتمل" alongside the rest,
/// so a captain could tap it, watch it tick, and leave believing the trip was
/// finished while the backend still had it `in_progress`, the seats still held
/// and the client's map still tracking. The three options that shadow a real
/// transition (boarding / departed / completed) are gone, and what remains is
/// framed as what it is: telling operations where you are.
class StatusUpdatePage extends StatelessWidget {
  const StatusUpdatePage({super.key, required this.tripId});

  final String tripId;

  /// The notes with no lifecycle counterpart. `boarding`, `departed` and
  /// `completed` are deliberately absent — each is performed for real by the
  /// execution screen's primary action, and offering a look-alike here that
  /// only writes a log line invites the captain to file the wrong one.
  static const _reportableStatuses = [
    CaptainTripStatus.headingToPickup,
    CaptainTripStatus.arrivedPickup,
    CaptainTripStatus.arrivedDestination,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripStatusUpdateCubit>(
      create: (_) => captainGetIt<TripStatusUpdateCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إبلاغ العمليات')),
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
                // Says plainly that this is a message, not a state change —
                // the captain should not leave here thinking the trip moved.
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  child: Text(
                    'هذه رسالة إلى فريق العمليات لتوضيح موقفك الحالي. '
                    'لا تغيّر مرحلة الرحلة — البدء والإنهاء من شاشة تنفيذ الرحلة.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                for (final status in _reportableStatuses) ...[
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

  /// The ladder walks the brand palette from its palest tint to its deepest
  /// shade as the trip progresses, so the colour itself reads as distance
  /// travelled. Boarding breaks out to amber on purpose — it's the one step
  /// that's waiting on the captain to act.
  Color _color(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup => CaptainColors.primaryLight,
      CaptainTripStatus.arrivedPickup => CaptainColors.primaryBright,
      CaptainTripStatus.boarding => CaptainColors.warning,
      CaptainTripStatus.departed => CaptainColors.primary,
      CaptainTripStatus.arrivedDestination => CaptainColors.primaryDeep,
      CaptainTripStatus.completed => CaptainColors.offline,
    };
  }
}
