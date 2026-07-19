import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/map_selection_panel.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/station_picker_sheet.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The bottom selection panel plus its station-picker sheets and confirm
/// navigation, driven by [MapPinsCubit].
class MapSelectionOverlay extends StatelessWidget {
  const MapSelectionOverlay({super.key, required this.state});

  final MapPinsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MapPinsCubit>();
    return MapSelectionPanel(
      pickup: state.selectedPickup,
      destination: state.selectedDestination,
      pickupEnabled: state.pickupPins.isNotEmpty,
      destinationEnabled: state.destinationPins.isNotEmpty,
      onPickup: () => _chooseStation(
        context,
        title: l10n.booking_pickupPoint,
        pins: state.pickupPins,
        selected: state.selectedPickup,
        onSelected: cubit.selectPickup,
      ),
      onDestination: () => _chooseStation(
        context,
        title: l10n.booking_destinationPoint,
        pins: state.destinationPins,
        selected: state.selectedDestination,
        onSelected: cubit.selectDestination,
      ),
      onConfirm: state.canConfirm
          ? () => _openRoutes(context, state.query)
          : null,
    );
  }

  Future<void> _chooseStation(
    BuildContext context, {
    required String title,
    required List<MapPinOption> pins,
    required MapPinOption? selected,
    required ValueChanged<MapPinOption> onSelected,
  }) async {
    final result = await showModalBottomSheet<MapPinOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          StationPickerSheet(title: title, pins: pins, selected: selected),
    );
    if (result != null && context.mounted) onSelected(result);
  }

  void _openRoutes(BuildContext context, BookingSearchQuery query) {
    if (!query.isComplete) return;
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: query.toArguments(),
    );
  }
}
