import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_progress_summary.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown for an in-progress trip: real route-completion progress from the
/// shared [RouteProgressEngine] (via a locally-scoped [TrackingCubit], the
/// same one the dedicated `/tracking` screen uses) with a graceful fallback
/// to a plain "track this trip" prompt if live data isn't available yet.
class TripLiveTrackingCard extends StatelessWidget {
  const TripLiveTrackingCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingCubit>(
      create: (_) => clientGetIt<TrackingCubit>()..load(bookingId: trip.id),
      child: _TripLiveTrackingCardBody(trip: trip),
    );
  }
}

class _TripLiveTrackingCardBody extends StatelessWidget {
  const _TripLiveTrackingCardBody({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TrackingCubit>().state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.primary.withAlpha(65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TripSoftIcon(
                icon: Icons.location_searching_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trips_liveTripInProgress,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/tracking',
                  arguments: {'bookingId': trip.id},
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: ClientColors.textInverse,
                ),
                child: Text(context.l10n.trips_liveTrackButton),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TripProgressSummary(state: state),
        ],
      ),
    );
  }
}
