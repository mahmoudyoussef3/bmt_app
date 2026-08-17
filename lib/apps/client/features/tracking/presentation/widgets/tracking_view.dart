import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../bloc/live_tracking_bloc.dart';
import '../bloc/live_tracking_state.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../formatters/tracking_labels.dart';
import 'sheet/tracking_sheet_body.dart';
import 'tracking_map.dart';
import 'tracking_sheet_scaffold.dart';
import 'tracking_signal_pill.dart';

/// The loaded screen: the map, one signal pill, and the details sheet.
///
/// On a phone the sheet is draggable over a full-bleed map. Past 900dp it
/// becomes a fixed side panel — the same widgets, not a second layout tree to
/// keep in sync. (The old screen maintained separate mobile and tablet
/// hierarchies, and they had already drifted apart.)
///
/// Two state holders meet here, and the split is the point: `TrackingCubit` is
/// consulted for what the trip *is*, `LiveTrackingBloc` for where the vehicle is.
/// Only the second one changes every few seconds, so only the widgets scoped to
/// it repaint.
class TrackingView extends StatefulWidget {
  const TrackingView({super.key, required this.labels});

  final TrackingLabels labels;

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _refresh() => context.read<TrackingCubit>().refresh();

  /// Scoped to the loaded trip, so a fix that only moves the vehicle does not
  /// rebuild the scaffold around it.
  Widget _scoped(Widget Function(TrackingLoaded loaded) build) {
    return BlocSelector<TrackingCubit, TrackingState, TrackingLoaded?>(
      selector: (state) => state is TrackingLoaded ? state : null,
      builder: (context, loaded) =>
          loaded == null ? const SizedBox.shrink() : build(loaded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;
    final labels = widget.labels;

    // The marker comes from the live feed and nowhere else. Once this rider
    // boards, the bloc answers `unavailable` and there is no fix to hand over —
    // which is the honest outcome, because passing the last known position on
    // would leave a marker frozen wherever the bus happened to be, presented as
    // a live one. The route line and the stops stay; those are still their
    // journey.
    final map = _scoped(
      (loaded) => BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
        builder: (context, live) => TrackingMap(
          routePoints: loaded.data.routePoints,
          vehicleFix: live is LiveTrackingActive ? live.fix : null,
          progress: live.progress,
          labels: labels,
          onRetry: _refresh,
          sheetController: isWide ? null : _sheetController,
          borderRadius: isWide ? 18 : 0,
        ),
      ),
    );

    final pill = BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
      builder: (context, live) => TrackingSignalPill(
        progress: live.progress,
        recordedAt: live is LiveTrackingActive ? live.fix.recordedAt : null,
        freshness: live is LiveTrackingActive ? live.freshness : null,
        link: live is LiveTrackingActive ? live.link : null,
        labels: labels,
      ),
    );

    // The sheet is built from the trip alone; the two sections inside it that a
    // position affects subscribe to the feed themselves.
    Widget sheet([ScrollController? scrollController]) => _scoped(
      (loaded) => TrackingSheetBody(
        trip: loaded.data,
        labels: labels,
        onRefresh: _refresh,
        isBoarding: loaded.isBoarding,
        boardingError: loaded.boardingError,
        scrollController: scrollController,
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Positioned.fill(child: map),
                  PositionedDirectional(top: 12, start: 12, child: pill),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 420,
            child: Material(
              color: ClientColors.surfaceFor(context),
              child: sheet(),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: map),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
          start: 16,
          child: pill,
        ),
        TrackingSheetScaffold(
          controller: _sheetController,
          builder: sheet,
        ),
      ],
    );
  }
}
