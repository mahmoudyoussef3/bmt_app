import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_app_bar.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_misc_widgets.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_screen_body.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_state_preview_sheet.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_loading_shimmer.dart';

/// Live trip tracking: a full flow from "upcoming ride" countdown through
/// driver-on-way, boarding, in-progress and completed states. Layout and
/// per-state content are delegated to small widgets under `widgets/`; this
/// screen only owns cubit loading and top-level scaffolding.
class TrackingScreen extends StatefulWidget {
  final bool shellMode;
  final String? bookingId;
  final String? tripId;

  const TrackingScreen({
    super.key,
    this.shellMode = false,
    this.bookingId,
    this.tripId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Owned here (not inside TrackingScreenBody, which rebuilds on every cubit
  // emission) so the drag position survives location/progress updates and the
  // live map can read the sheet's current extent for camera padding.
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    context.read<TrackingCubit>().load(
      bookingId: widget.bookingId,
      tripId: widget.tripId,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 768;

    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        if (state is TrackingLoading) {
          return Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            body: const MapLoadingShimmer(message: 'Loading your trip…'),
          );
        }
        if (state is TrackingError) {
          return Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            body: ClientErrorCard.fullScreen(message: state.message),
          );
        }

        final loaded = state as TrackingLoaded;
        final isActive = loaded.currentState != TrackingTripState.notStarted;
        void onPreviewStates() => showTrackingStatePreviewSheet(
          context,
          currentState: loaded.currentState,
          onChangeState: (s) => context.read<TrackingCubit>().changeState(s),
        );

        return Scaffold(
          extendBodyBehindAppBar: isActive,
          backgroundColor: isActive
              ? scheme.surface
              : ClientColors.surfaceFor(context),
          appBar: TrackingAppBar(
            isActive: isActive,
            title: loaded.title,
            showPreviewAction: widget.shellMode,
            onPreviewStates: onPreviewStates,
            onRefresh: () => context.read<TrackingCubit>().refresh(),
          ),
          body: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: TrackingBackgroundGlow(
                  color: ClientColors.primary.withAlpha(20),
                  size: 300,
                ),
              ),
              Positioned(
                bottom: -50,
                left: -100,
                child: TrackingBackgroundGlow(
                  color: ClientColors.journeyCyan.withAlpha(15),
                  size: 250,
                ),
              ),
              Positioned.fill(
                child: TrackingScreenBody(
                  loaded: loaded,
                  shellMode: widget.shellMode,
                  isTablet: isTablet,
                  sheetController: _sheetController,
                ),
              ),
              if (loaded.isRefreshing)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: ClientColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
