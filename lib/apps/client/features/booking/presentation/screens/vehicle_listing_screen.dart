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
import 'package:bmt_app/l10n/app_localizations.dart';

/// شاشة اختيار العربية.
///
/// UX notes:
/// - الشاشة مقصودة تكون هادية وبسيطة.
/// - لا يوجد Hero كبير أو كلام تسويقي زائد.
/// - التركيز الأساسي على كروت العربيات نفسها.
/// - كل النصوص بالعربي.
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
    context.read<BookingCubit>().loadVehicles(sort: _sort, routeId: _query.routeId);
  }

  void _openDetails(VehicleDetailData vehicle) {
    Navigator.pushNamed(
      context,
      BookingRoutes.vehicleDetails,
      arguments: {'vehicleId': vehicle.id, ..._query.toArguments()},
    );
  }

  void _selectVehicle(VehicleDetailData vehicle) {
    setState(() => _selectedVehicleId = vehicle.id);
    Navigator.pushNamed(context, '/seat-selection', arguments: {'tripId': vehicle.id});
  }

  void _selectSort(VehicleSortOption option) {
    if (_sort == option) return;
    setState(() => _sort = option);
    context.read<BookingCubit>().loadVehicles(sort: option, routeId: _query.routeId);
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
            title: AppLocalizations.of(context)!.booking_selectVehicle,
            query: _query,
            body: _VehicleListingBody(
              state: state,
              vehicles: vehicles,
              sort: _sort,
              selectedVehicleId: _selectedVehicleId,
              onRetry: () =>
                  context.read<BookingCubit>().loadVehicles(sort: _sort, routeId: _query.routeId),
              onSort: _selectSort,
              onOpenDetails: _openDetails,
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
    required this.onOpenDetails,
    required this.onSelect,
  });

  final BookingState state;
  final List<VehicleDetailData> vehicles;
  final VehicleSortOption sort;
  final String? selectedVehicleId;
  final VoidCallback onRetry;
  final ValueChanged<VehicleSortOption> onSort;
  final ValueChanged<VehicleDetailData> onOpenDetails;
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
            onViewDetails: () => onOpenDetails(vehicle),
            onSelect: () => onSelect(vehicle),
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
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.booking_availableVehicles,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context)!.booking_availableOptions(vehiclesCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w600,
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
      (VehicleSortOption.recommended, AppLocalizations.of(context)!.booking_sortRecommended, Icons.auto_awesome_rounded),
      (VehicleSortOption.priceLow, AppLocalizations.of(context)!.booking_sortPriceLow, Icons.payments_rounded),
      (VehicleSortOption.rating, AppLocalizations.of(context)!.booking_sortRating, Icons.star_rounded),
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? scheme.primary.withAlpha(26) : scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? scheme.primary.withAlpha(120) : scheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? scheme.primary : scheme.onSurface.withAlpha(160),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: active ? scheme.primary : scheme.onSurface,
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
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.primary, width: 1.6),
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
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.booking_searchingBestOptions,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error, size: 44),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.booking_errorLoadingVehicles,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.common_tryAgain),
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
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus_outlined,
                color: scheme.primary,
                size: 46,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.booking_noVehiclesAvailable,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.booking_noVehiclesDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.search_rounded),
                label: Text(AppLocalizations.of(context)!.booking_searchAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
