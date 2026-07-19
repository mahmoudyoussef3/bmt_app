import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/map_selection_overlay.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/map_states.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Selects real pickup and destination stations and previews them on a map.
class MapRouteSelectionScreen extends StatelessWidget {
  const MapRouteSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MapPinsCubit>();
    return BlocBuilder<MapPinsCubit, MapPinsState>(
      builder: (context, state) {
        if (state is! MapPinsLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.booking_selectOnMap)),
            body: state is MapPinsError
                ? MapErrorState(message: state.message, onRetry: cubit.reload)
                : const MapLoadingState(),
          );
        }
        return Scaffold(
          backgroundColor: ClientColors.surfaceSubtleFor(context),
          appBar: AppBar(
            title: Text(l10n.booking_selectOnMap),
            actions: [
              IconButton(
                tooltip: l10n.tracking_refresh,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: cubit.reload,
              ),
              ClientButton.text(
                label: l10n.booking_popular,
                onPressed: () => Navigator.pushNamed(
                  context,
                  BookingRoutes.popularRoutes,
                  arguments: state.query.toArguments(),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: EasyWayRouteMapView(
                  pickup: state.selectedPickup,
                  destination: state.selectedDestination,
                  cameraPadding: const EdgeInsets.fromLTRB(48, 64, 48, 290),
                ),
              ),
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: MapSelectionOverlay(state: state),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
