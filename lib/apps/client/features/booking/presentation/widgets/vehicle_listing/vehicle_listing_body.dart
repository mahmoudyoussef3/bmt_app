import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_compare_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_listing/vehicle_item_shell.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_listing/vehicle_listing_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_listing/vehicle_listing_states.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_listing/vehicle_sort_bar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Body of the vehicle listing: loading / error / empty / list of vehicles.
class VehicleListingBody extends StatelessWidget {
  const VehicleListingBody({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.vehicles,
    required this.sort,
    required this.selectedVehicleId,
    required this.onRetry,
    required this.onSort,
    required this.onSelect,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<VehicleDetailData> vehicles;
  final VehicleSortOption sort;
  final String? selectedVehicleId;
  final VoidCallback onRetry;
  final ValueChanged<VehicleSortOption> onSort;
  final ValueChanged<VehicleDetailData> onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const VehicleListingLoadingView();
    if (errorMessage != null) {
      return VehicleListingMessageCard(
        icon: Icons.error_outline_rounded,
        iconColor: ClientColors.journeyRed,
        title: context.l10n.booking_errorLoadingVehicles,
        message: errorMessage!,
        actionLabel: context.l10n.common_tryAgain,
        actionIcon: const Icon(Icons.refresh_rounded, size: 18),
        onAction: onRetry,
      );
    }
    if (vehicles.isEmpty) {
      return VehicleListingMessageCard(
        icon: Icons.directions_bus_outlined,
        iconColor: ClientColors.primary,
        title: context.l10n.booking_noVehiclesAvailable,
        message: context.l10n.booking_noVehiclesDesc,
        actionLabel: context.l10n.booking_searchAgain,
        actionIcon: const Icon(Icons.search_rounded, size: 18),
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: vehicles.length + 2,
      separatorBuilder: (context, index) =>
          SizedBox(height: index == 0 ? 12 : 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return VehicleListingHeader(vehiclesCount: vehicles.length);
        }
        if (index == 1) {
          return VehicleSortBar(selected: sort, onSelected: onSort);
        }
        final vehicle = vehicles[index - 2];
        final selected = selectedVehicleId == vehicle.id;
        return VehicleItemShell(
          selected: selected,
          child: VehicleCompareCard(
            vehicle: vehicle,
            onSelect: () => onSelect(vehicle),
            selected: selected,
          ),
        );
      },
    );
  }
}
