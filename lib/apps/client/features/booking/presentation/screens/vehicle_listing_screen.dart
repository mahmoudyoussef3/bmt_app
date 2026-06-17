import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_compare_card.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Trip and vehicle selection screen.
class VehicleListingScreen extends StatefulWidget {
  const VehicleListingScreen({super.key});

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  VehicleSortOption _sort = VehicleSortOption.recommended;
  String? _selectedVehicleId;
  late BookingSearchQuery _query;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);

    if (_didLoad) return;
    _didLoad = true;
    context.read<BookingCubit>().loadVehicles(
      sort: _sort,
      routeId: _query.routeId,
    );
  }

  void _selectVehicle(VehicleDetailData vehicle) {
    setState(() => _selectedVehicleId = vehicle.id);
    Navigator.pushNamed(
      context,
      '/seat-selection',
      arguments: {'tripId': vehicle.id, ..._query.toArguments()},
    );
  }

  void _selectSort(VehicleSortOption option) {
    if (_sort == option) return;
    setState(() => _sort = option);
    context.read<BookingCubit>().loadVehicles(
      sort: option,
      routeId: _query.routeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final vehicles = state is VehiclesLoaded
              ? state.vehicles
              : <VehicleDetailData>[];

          return BookingFlowScaffold(
            title: 'Choose trip and vehicle',
            query: _query,
            body: _VehicleListingBody(
              state: state,
              vehicles: vehicles,
              sort: _sort,
              selectedVehicleId: _selectedVehicleId,
              onRetry: () => context.read<BookingCubit>().loadVehicles(
                sort: _sort,
                routeId: _query.routeId,
              ),
              onSort: _selectSort,
              onSelect: _selectVehicle,
            ),
          );
        },
      ),
    );
  }
}

class _VehicleListingBody extends StatelessWidget {
  const _VehicleListingBody({
    required this.state,
    required this.vehicles,
    required this.sort,
    required this.selectedVehicleId,
    required this.onRetry,
    required this.onSort,
    required this.onSelect,
  });

  final BookingState state;
  final List<VehicleDetailData> vehicles;
  final VehicleSortOption sort;
  final String? selectedVehicleId;
  final VoidCallback onRetry;
  final ValueChanged<VehicleSortOption> onSort;
  final ValueChanged<VehicleDetailData> onSelect;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) {
      return const _BookingLoadingState();
    }

    if (state is BookingError) {
      return _BookingErrorState(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }

    if (vehicles.isEmpty) {
      return _BookingEmptyState(onRetry: onRetry);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: vehicles.length + 2,
      separatorBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 12);
        if (index == 1) return const SizedBox(height: 14);
        return const SizedBox(height: 14);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CompactHeader(vehiclesCount: vehicles.length);
        }

        if (index == 1) {
          return _SortBar(selected: sort, onSelected: onSort);
        }

        final vehicle = vehicles[index - 2];
        final selected = selectedVehicleId == vehicle.id;

        return _VehicleItemShell(
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

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.vehiclesCount});

  final int vehiclesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ClientColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: ClientColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available trips',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$vehiclesCount trip options with assigned vehicles',
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.selected, required this.onSelected});

  final VehicleSortOption selected;
  final ValueChanged<VehicleSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      (VehicleSortOption.recommended, 'Earliest', Icons.schedule_rounded),
      (VehicleSortOption.priceLow, 'Lowest price', Icons.payments_rounded),
      (VehicleSortOption.seats, 'Most seats', Icons.event_seat_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((entry) {
          final active = selected == entry.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _SortChip(
              icon: entry.$3,
              label: entry.$2,
              active: active,
              onTap: () => onSelected(entry.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? ClientColors.primaryLight : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? ClientColors.primaryMuted : ClientColors.borderFor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? ClientColors.primary
                  : ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ClientTypography.bodySmall(context).copyWith(
                color: active
                    ? ClientColors.primary
                    : ClientColors.textPrimaryFor(context),
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleItemShell extends StatelessWidget {
  const _VehicleItemShell({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ClientColors.primary, width: 1.6),
            )
          : null,
      child: child,
    );
  }
}

class _BookingLoadingState extends StatelessWidget {
  const _BookingLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ClientColors.primary),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.booking_searchingBestOptions,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
          ],
        ),
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
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ClientColors.journeyRed,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.booking_errorLoadingVehicles,
                style: ClientTypography.headingSmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 14),
              ClientButton(
                label: AppLocalizations.of(context)!.common_tryAgain,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingEmptyState extends StatelessWidget {
  const _BookingEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                color: ClientColors.primary,
                size: 46,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.booking_noVehiclesAvailable,
                style: ClientTypography.headingSmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.booking_noVehiclesDesc,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 14),
              ClientButton(
                label: AppLocalizations.of(context)!.booking_searchAgain,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.search_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
