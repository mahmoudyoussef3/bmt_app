import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Reports the outcome of the last cancellation as a snackbar. The state
/// carries the outcome for exactly one emit, so a rebuild never replays it.
void showTripCancellationNotice(BuildContext context, TripsLoaded state) {
  final failure = state.cancelFailure;
  final cancelled = state.cancelledReference;
  if (failure == null && cancelled == null) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          failure ?? context.l10n.trips_cancelSuccessMessage(cancelled ?? ''),
        ),
        backgroundColor: failure != null ? ClientColors.journeyRed : null,
      ),
    );
}
