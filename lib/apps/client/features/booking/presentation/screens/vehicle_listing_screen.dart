import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_listing_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_listing_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_listing/vehicle_listing_body.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Trip and vehicle selection screen for the current search.
class VehicleListingScreen extends StatelessWidget {
  const VehicleListingScreen({super.key, required this.query});

  final BookingSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleListingCubit>();
    return BlocBuilder<VehicleListingCubit, VehicleListingState>(
      builder: (context, state) {
        final loaded = state is VehicleListingLoaded ? state : null;
        final sort = loaded?.sort ?? VehicleSortOption.recommended;
        return BookingFlowScaffold(
          title: context.l10n.booking_chooseTripAndVehicle,
          query: query,
          actions: [
            IconButton(
              tooltip: context.l10n.tracking_refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => cubit.load(routeId: query.routeId, sort: sort),
            ),
          ],
          body: VehicleListingBody(
            isLoading: state is VehicleListingLoading,
            errorMessage: state is VehicleListingError ? state.message : null,
            vehicles: loaded?.vehicles ?? const <VehicleDetailData>[],
            sort: sort,
            selectedVehicleId: loaded?.selectedVehicleId,
            onRetry: () => cubit.load(routeId: query.routeId, sort: sort),
            onSort: cubit.setSort,
            onSelect: (vehicle) => _selectVehicle(context, vehicle),
          ),
        );
      },
    );
  }

  void _selectVehicle(BuildContext context, VehicleDetailData vehicle) {
    context.read<VehicleListingCubit>().select(vehicle.id);
    Navigator.pushNamed(
      context,
      '/seat-selection',
      arguments: {'tripId': vehicle.id, ...query.toArguments()},
    );
  }
}
