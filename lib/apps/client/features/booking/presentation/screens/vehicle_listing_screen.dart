import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_compare_card.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Compare and select from available vehicles before booking.
class VehicleListingScreen extends StatefulWidget {
  const VehicleListingScreen({super.key});

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  VehicleSortOption _sort = VehicleSortOption.recommended;
  String? _highlightedId;
  late BookingSearchQuery _query;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
    context.read<BookingCubit>().loadVehicles(sort: _sort);
  }

  void _openDetails(VehicleDetailData vehicle) {
    Navigator.pushNamed(
      context,
      BookingRoutes.vehicleDetails,
      arguments: {'vehicleId': vehicle.id, ..._query.toArguments()},
    );
  }

  void _selectVehicle(VehicleDetailData vehicle) {
    Navigator.pushNamed(context, '/seat-selection');
  }

  void _selectSort(VehicleSortOption option) {
    setState(() => _sort = option);
    context.read<BookingCubit>().loadVehicles(sort: option);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final vehicles = state is VehiclesLoaded
            ? state.vehicles
            : <VehicleDetailData>[];

        return BookingFlowScaffold(
          title: 'Choose Your Vehicle',
          query: _query,
          body: _VehicleListingBody(
            state: state,
            vehicles: vehicles,
            sort: _sort,
            highlightedId: _highlightedId,
            onRetry: () =>
                context.read<BookingCubit>().loadVehicles(sort: _sort),
            onSort: _selectSort,
            onOpenDetails: _openDetails,
            onSelect: (vehicle) {
              setState(() => _highlightedId = vehicle.id);
              _selectVehicle(vehicle);
            },
          ),
        );
      },
    );
  }
}

class _VehicleListingBody extends StatelessWidget {
  const _VehicleListingBody({
    required this.state,
    required this.vehicles,
    required this.sort,
    required this.highlightedId,
    required this.onRetry,
    required this.onSort,
    required this.onOpenDetails,
    required this.onSelect,
  });

  final BookingState state;
  final List<VehicleDetailData> vehicles;
  final VehicleSortOption sort;
  final String? highlightedId;
  final VoidCallback onRetry;
  final ValueChanged<VehicleSortOption> onSort;
  final ValueChanged<VehicleDetailData> onOpenDetails;
  final ValueChanged<VehicleDetailData> onSelect;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BookingError) {
      return _BookingErrorState(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(
          title: 'Compare vehicles',
          subtitle:
              '${vehicles.length} options · review comfort, driver & price',
        ),
        const SizedBox(height: 12),
        _SortBar(selected: sort, onSelected: onSort),
        const SizedBox(height: 16),
        ...vehicles.map((vehicle) {
          final highlighted = highlightedId == vehicle.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: highlighted
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              child: VehicleCompareCard(
                vehicle: vehicle,
                onViewDetails: () => onOpenDetails(vehicle),
                onSelect: () => onSelect(vehicle),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.selected, required this.onSelected});

  final VehicleSortOption selected;
  final ValueChanged<VehicleSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const options = [
      (VehicleSortOption.recommended, 'Recommended'),
      (VehicleSortOption.priceLow, 'Price'),
      (VehicleSortOption.rating, 'Rating'),
      (VehicleSortOption.seats, 'Seats'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((entry) {
          final active = selected == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.$2),
              selected: active,
              onSelected: (_) => onSelected(entry.$1),
              selectedColor: scheme.primary.withAlpha(50),
              checkmarkColor: scheme.primary,
              labelStyle: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingErrorState extends StatelessWidget {
  const _BookingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
