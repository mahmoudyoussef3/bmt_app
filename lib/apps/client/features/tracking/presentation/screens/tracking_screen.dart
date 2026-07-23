import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_loading_shimmer.dart';

import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../formatters/tracking_labels.dart';
import '../widgets/tracking_empty_view.dart';
import '../widgets/tracking_view.dart';

/// Live trip tracking.
///
/// The screen owns nothing but its four states — loading, empty, error, and the
/// live view. The trip state it shows is always the operation's real one; there
/// is no way from here to put the screen into a state the trip is not in.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.bookingId, this.tripId});

  final String? bookingId;
  final String? tripId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingCubit>().load(
      bookingId: widget.bookingId,
      tripId: widget.tripId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = TrackingLabels(
      l10n,
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ClientColors.surfaceFor(context),
      // The header floats over the live map, so it carries no surface of its
      // own and lets the map show through.
      appBar: ClientAppBar(
        title: l10n.tracking_title,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.tracking_refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TrackingCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<TrackingCubit, TrackingState>(
        // The live view manages its own finer-grained rebuilds; rebuilding the
        // whole scaffold on every GPS fix would tear the map down with it.
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) => switch (state) {
          TrackingLoading() => MapLoadingShimmer(
            message: l10n.tracking_loading,
          ),
          TrackingEmpty() => const TrackingEmptyView(),
          TrackingError(:final message) => ClientErrorCard.fullScreen(
            message: message,
            onRetry: () => context.read<TrackingCubit>().refresh(),
          ),
          TrackingLoaded() => TrackingView(labels: labels),
        },
      ),
    );
  }
}
