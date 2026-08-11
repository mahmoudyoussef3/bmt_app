import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../domain/entities/station_passenger.dart';
import '../cubit/station_progress_cubit.dart';
import 'no_show_reason_sheet.dart';

/// "Who didn't board?" → "Why not?".
///
/// Two deliberate steps. A single-tap "skip everyone" would satisfy the gate
/// just as well and would make the gate meaningless; naming one passenger at a
/// time, with a reason each, is the point.
Future<void> showStationNoShowSheet(
  BuildContext context, {
  required TripStation station,
}) async {
  final cubit = context.read<StationProgressCubit>();
  final passengers = await cubit.passengersAt(station);
  if (!context.mounted) return;

  final pending = passengers.where((p) => p.isPending).toList(growable: false);
  if (pending.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('لا يوجد ركاب في انتظار الصعود هنا')),
    );
    return;
  }

  final passenger = await showModalBottomSheet<StationPassenger>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PendingPassengerSheet(station: station, passengers: pending),
  );
  if (passenger == null || !context.mounted) return;

  final resolution = await showNoShowReasonSheet(
    context,
    passengerName: passenger.name,
    seatLabel: passenger.seatLabel,
  );
  if (resolution == null) return;

  await cubit.resolveNoShow(
    passengerId: passenger.id,
    reason: resolution.reason,
    note: resolution.note,
  );
}

class _PendingPassengerSheet extends StatelessWidget {
  const _PendingPassengerSheet({
    required this.station,
    required this.passengers,
  });

  final TripStation station;
  final List<StationPassenger> passengers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r32),
      ),
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Grabber(),
          const SizedBox(height: CaptainDesignTokens.s24),
          Text(
            'ركاب في انتظار الصعود',
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Text(
            station.name,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s20),
          for (final passenger in passengers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_rounded,
                color: CaptainColors.primary,
              ),
              title: Text(
                passenger.name,
                style: CaptainTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: passenger.seatLabel.isEmpty
                  ? null
                  : Text('مقعد ${passenger.seatLabel}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(context, passenger),
            ),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: CaptainColors.dividerFor(context),
          borderRadius: CaptainDesignTokens.br8,
        ),
      ),
    );
  }
}
