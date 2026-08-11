import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

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

  /// Every section is scoped to the loaded state, so a fix that only moves the
  /// vehicle does not rebuild the scaffold around it.
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

    final map = _scoped(
      (loaded) => TrackingMap(
        routePoints: loaded.data.routePoints,
        vehicleFix: loaded.data.vehicleFix,
        progress: loaded.progress,
        labels: labels,
        onRetry: _refresh,
        sheetController: isWide ? null : _sheetController,
        borderRadius: isWide ? 18 : 0,
      ),
    );

    final pill = _scoped(
      (loaded) => TrackingSignalPill(
        progress: loaded.progress,
        recordedAt: loaded.data.vehicleFix?.recordedAt,
        labels: labels,
      ),
    );

    Widget sheet([ScrollController? scrollController]) => _scoped(
      (loaded) => TrackingSheetBody(
        trip: loaded.data,
        progress: loaded.progress,
        labels: labels,
        onRefresh: _refresh,
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
