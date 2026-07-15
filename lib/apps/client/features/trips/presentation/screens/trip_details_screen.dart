import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_empty_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_error_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_loading_view.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Premium trip details screen with a branded boarding pass, route timeline,
/// driver actions, vehicle info, a live seat map, payment summary, and the
/// cancel/track/review flows — with loading, empty, and error states.
class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, this.tripId});

  final String? tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  String? _tripId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tripId = _resolveTripId(context);
    if (_tripId == tripId) return;
    _tripId = tripId;
    context.read<TripsCubit>().loadTripDetails(_tripId);
  }

  String? _resolveTripId(BuildContext context) {
    if (widget.tripId != null) return widget.tripId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['tripId']?.toString();
    }
    return null;
  }

  void _reportCancellation(BuildContext context, TripsLoaded state) {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripsCubit, TripsState>(
      listener: (context, state) {
        if (state is TripsLoaded) _reportCancellation(context, state);
      },
      builder: (context, state) {
        if (state is TripsLoading) {
          return const TripLoadingView();
        }

        if (state is TripsError) {
          return TripErrorView(
            message: state.message,
            onRetry: () => context.read<TripsCubit>().loadTripDetails(_tripId),
          );
        }

        final trip = state is TripsLoaded ? state.selectedTrip : null;
        if (trip == null) {
          return const TripEmptyView();
        }

        return TripDetailsView(
          trip: trip,
          cancelInFlight: (state as TripsLoaded).cancelInFlight,
          onRefresh: () => context.read<TripsCubit>().loadTripDetails(_tripId),
        );
      },
    );
  }
}
