import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../../domain/entities/tracking_trip.dart';
import '../../cubit/tracking_cubit.dart';
import '../../formatters/tracking_labels.dart';

/// The rider's own boarding step, in three states.
///
///   waiting  — the vehicle has not reached their stop, so there is nothing to
///              confirm and the card says what it is waiting for.
///   ready    — the vehicle is standing at their stop: "هل صعدت إلى السيارة؟"
///   boarded  — confirmed, and the live-vehicle map has gone away. The card
///              *explains that*, because a rider who watched a map disappear
///              without being told will assume something broke.
///
/// Nothing here decides anything. `passenger_confirm_boarding` re-checks that
/// this is the rider's own booking, that it is paid for, and that the vehicle is
/// really at their station; this card just makes the button available at the
/// moment the answer is likely to be yes.
class TrackingBoardingCard extends StatelessWidget {
  const TrackingBoardingCard({
    super.key,
    required this.trip,
    required this.labels,
    required this.isBoarding,
    this.boardingError,
  });

  final TrackingTripData trip;
  final TrackingLabels labels;
  final bool isBoarding;
  final String? boardingError;

  /// Whether this rider has anything to see here at all.
  ///
  /// A rider with no booking of their own, or one whose payment never cleared,
  /// gets no boarding step — the same set the database admits.
  static bool isRelevantFor(TrackingTripData trip) {
    if (trip.tripState.isFinished) return false;
    final rider = trip.rider;
    return rider.hasBoarded || rider.canConfirmBoarding;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;

    if (trip.rider.hasBoarded) {
      return _Panel(
        icon: Icons.check_circle_rounded,
        color: ClientColors.journeyCyanFor(context),
        title: l10n.tracking_boardedTitle,
        body: l10n.tracking_boardedBody,
      );
    }

    final station = trip.riderStation;
    final stationName =
        station?.name ?? trip.rider.boardingName ?? l10n.tracking_boardAt;

    if (!trip.isVehicleAtRiderStation) {
      return _Panel(
        icon: Icons.schedule_rounded,
        color: ClientColors.journeyAmberFor(context),
        title: l10n.tracking_boardingWaitingTitle,
        body: l10n.tracking_boardingWaitingBody(stationName),
      );
    }

    return _Panel(
      icon: Icons.directions_bus_filled_rounded,
      color: ClientColors.primaryFor(context),
      title: l10n.tracking_boardingTitle,
      body: l10n.tracking_boardingBody(stationName),
      footnote: _pendingLine(station),
      error: boardingError,
      onDismissError: () =>
          context.read<TrackingCubit>().dismissBoardingError(),
      action: ClientButton(
        label: l10n.tracking_boardingAction,
        isLoading: isBoarding,
        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
        onPressed: () => context.read<TrackingCubit>().confirmBoarding(),
      ),
    );
  }

  /// How many riders this stop is still waiting on — the same number the captain
  /// is looking at, so a rider can see why the vehicle has not left yet instead
  /// of assuming it is late.
  String? _pendingLine(TripStation? station) {
    if (station == null || station.expectedBoardings == 0) return null;
    return labels.l10n.tracking_boardingPending(station.pendingCount);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.footnote,
    this.action,
    this.error,
    this.onDismissError,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? footnote;
  final Widget? action;
  final String? error;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    final note = footnote;
    final failure = error;

    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ClientTypography.headingSmall(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: 12),
            _ErrorLine(message: failure, onDismiss: onDismissError),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ClientColors.journeyAmberFor(context).withAlpha(28),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
