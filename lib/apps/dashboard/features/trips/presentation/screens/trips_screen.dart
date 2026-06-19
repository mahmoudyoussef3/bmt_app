import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/presentation/cubit/trip_passengers_cubit.dart';

import '../widgets/trip_pricing_tab.dart';
import '../widgets/trip_creation_wizard.dart';
import '../widgets/trips_analytics.dart';

/// This file contains an improved implementation of the TripsScreen.
///
/// The original TripsScreen grew organically and became quite large and
/// difficult to navigate.  In this revised version, the UI is broken up
/// into smaller helper widgets with clear responsibilities.  We also
/// improve responsiveness by relying on `LayoutBuilder` to choose
/// between grid or list layouts depending on available width.  Where
/// appropriate we leverage Flutter's built–in widgets such as
/// `DataTable` for tabular data instead of hand‑rolling a table with
/// Expanded widgets.  This improves both semantics and accessibility.

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripsListCubit>(
          create: (_) => dashboardDi<TripsListCubit>()..load(),
        ),
        BlocProvider<TripDetailsCubit>(
          create: (_) => dashboardDi<TripDetailsCubit>(),
        ),
        BlocProvider<TripSeatsCubit>(
          create: (_) => dashboardDi<TripSeatsCubit>(),
        ),
        BlocProvider<TripPricingCubit>(
          create: (_) => dashboardDi<TripPricingCubit>(),
        ),
        BlocProvider<TripPassengersCubit>(
          create: (_) => dashboardDi<TripPassengersCubit>(),
        ),
      ],
      child: const _TripsView(),
    );
  }
}

/// The main scaffold for the Trips feature.  Handles the various BLoC
/// listeners and delegates the actual view to a private stateful widget
/// so we can manage a scroll controller cleanly.
class _TripsView extends StatefulWidget {
  const _TripsView();
  @override
  State<_TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<_TripsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MultiBlocListener(
        listeners: [
          // Propagate seat updates back into details and list
          BlocListener<TripSeatsCubit, TripSeatsState>(
            listener: (context, state) {
              if (state is TripSeatsSuccess) {
                context.read<TripDetailsCubit>().updateTripLocally(state.trip);
                context.read<TripsListCubit>().updateTripInList(state.trip);
              }
            },
          ),
          // Propagate passenger updates back into details and list
          BlocListener<TripPassengersCubit, TripPassengersState>(
            listener: (context, state) {
              if (state is TripPassengersSuccess) {
                context.read<TripDetailsCubit>().updateTripLocally(state.trip);
                context.read<TripsListCubit>().updateTripInList(state.trip);
              }
            },
          ),
        ],
        child: BlocBuilder<TripsListCubit, TripsListState>(
          builder: (context, listState) {
            // Top‑level loading and error states
            if (listState is TripsListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (listState is TripsListError) {
              return Center(
                child: Text(
                  listState.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            if (listState is! TripsListLoaded) {
              return const SizedBox.shrink();
            }

            return BlocBuilder<TripDetailsCubit, TripDetailsState>(
              builder: (context, detailsState) {
                OperationTrip? selectedTrip;
                if (detailsState is TripDetailsLoaded) {
                  selectedTrip = detailsState.trip;
                }
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.large),
                  children: [
                    const _Header(),
                    if (selectedTrip != null) ...[
                      const SizedBox(height: AppSpacing.large),
                      _TripWorkspace(trip: selectedTrip),
                    ],
                    const SizedBox(height: AppSpacing.large),
                    _DashboardKPIs(listState: listState),
                    const SizedBox(height: AppSpacing.large),
                    TripsAnalytics(state: listState),
                    const SizedBox(height: AppSpacing.large),
                    _FilterBar(listState: listState),
                    const SizedBox(height: AppSpacing.medium),
                    _TripsTable(
                      listState: listState,
                      onOpenTrip: _openTrip,
                      onDuplicateTrip: _duplicateTrip,
                      onDeleteTrip: _deleteTrip,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Show details for the selected trip and scroll to top.
  void _openTrip(OperationTrip trip) {
    context.read<TripDetailsCubit>().showDetails(trip);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _duplicateTrip(OperationTrip source) {
    final tripsCubit = context.read<TripsListCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<TripCreationCubit>()..loadWizardData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripCreationWizardDialog(prefillTrip: source),
        ),
      ),
    ).then((_) => tripsCubit.load());
  }

  Future<void> _deleteTrip(OperationTrip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الرحلة نهائياً'),
        content: Text(
          'سيتم حذف الرحلة "${trip.route}" من قاعدة البيانات. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final detailsCubit = context.read<TripDetailsCubit>();
    final detailsState = detailsCubit.state;
    if (detailsState is TripDetailsLoaded && detailsState.trip.id == trip.id) {
      detailsCubit.closeDetails();
    }
    await context.read<TripsListCubit>().deleteTrip(trip.id);
  }
}

/// Header panel with page title and global actions.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return DashboardModuleHeader(
      icon: Icons.directions_bus_rounded,
      title: 'إدارة الرحلات',
      subtitle: 'جدولة الرحلات وتعيين السائقين وإدارة المقاعد والأسعار.',
      actions: [
        FilledButton.icon(
          onPressed: () => _openCreateTripWizard(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إنشاء رحلة'),
        ),
      ],
    );
  }

  void _openCreateTripWizard(BuildContext context) {
    final tripsCubit = context.read<TripsListCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<TripCreationCubit>()..loadWizardData(),
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: TripCreationWizardDialog(),
        ),
      ),
    ).then((_) => tripsCubit.load());
  }
}

/// Displays the high‑level summary KPIs for trips.  We use a responsive
/// grid to show four cards on larger screens or two cards on small
/// screens.  Each card presents a label, an icon, and a value.
class _DashboardKPIs extends StatelessWidget {
  final TripsListLoaded listState;
  const _DashboardKPIs({required this.listState});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DashboardKpiGrid(
      itemExtent: 84,
      children: [
        DashboardKpiCard(
          label: 'الرحلات اليوم',
          value: '${listState.todayTrips}',
          icon: Icons.today_outlined,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          label: 'الرحلات القادمة',
          value: '${listState.upcomingTrips}',
          icon: Icons.schedule_rounded,
          color: scheme.secondary,
        ),
        DashboardKpiCard(
          label: 'الرحلات الجارية',
          value: '${listState.runningTrips}',
          icon: Icons.near_me_outlined,
          color: scheme.tertiary,
        ),
        DashboardKpiCard(
          label: 'الرحلات المكتملة',
          value: '${listState.completedTrips}',
          icon: Icons.check_circle_outline,
          color: scheme.primary,
        ),
      ],
    );
  }
}

/// Filter bar combining a search field with several dropdown filters.  All
/// filter widgets wrap automatically when the viewport is narrow.
class _FilterBar extends StatelessWidget {
  final TripsListLoaded listState;
  const _FilterBar({required this.listState});
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsListCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1050;
          final searchField = SizedBox(
            width: compact ? constraints.maxWidth : 280,
            child: TextField(
              onChanged: cubit.search,
              decoration: const InputDecoration(
                labelText: 'بحث برقم الرحلة، المسار، السائق أو المركبة',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          );
          final filters = [
            SizedBox(width: 180, child: _StatusFilter(state: listState)),
            SizedBox(
              width: 220,
              child: _StringFilter(
                label: 'المسار',
                value: listState.routeFilter,
                values: listState.routes,
                onChanged: cubit.filterRoute,
              ),
            ),
            SizedBox(
              width: 190,
              child: _StringFilter(
                label: 'السائق',
                value: listState.driverFilter,
                values: listState.drivers,
                onChanged: cubit.filterDriver,
              ),
            ),
            SizedBox(
              width: 190,
              child: _StringFilter(
                label: 'المركبة',
                value: listState.vehicleFilter,
                values: listState.vehicles,
                onChanged: cubit.filterVehicle,
              ),
            ),
            SizedBox(
              width: 190,
              child: _StringFilter(
                label: 'الإشغال',
                value: listState.occupancyFilter,
                values: listState.occupancyBands,
                onChanged: cubit.filterOccupancy,
              ),
            ),
            SizedBox(
              width: 180,
              child: _StringFilter(
                label: 'التاريخ',
                value: listState.dateFilter,
                values: listState.dates,
                onChanged: cubit.filterDate,
              ),
            ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickFilterChips(state: listState),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [searchField, ...filters],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickFilterChips extends StatelessWidget {
  final TripsListLoaded state;

  const _QuickFilterChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', 'الكل', state.trips.length),
      ('today', 'اليوم', state.todayTrips),
      ('upcoming', 'قادمة', state.upcomingTrips),
      ('active', 'نشطة', state.runningTrips),
      ('completed', 'مكتملة', state.completedTrips),
      (
        'cancelled',
        'ملغاة',
        state.trips
            .where((trip) => trip.status == OperationTripStatus.cancelled)
            .length,
      ),
    ];
    final cubit = context.read<TripsListCubit>();
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: items.map((item) {
        final selected = state.quickFilter == item.$1;
        return FilterChip(
          selected: selected,
          showCheckmark: false,
          label: Text('${item.$2} ${item.$3}'),
          onSelected: (_) => cubit.filterQuick(item.$1),
        );
      }).toList(),
    );
  }
}

/// Dropdown filter for trip status.  We use a nullable value so that
/// selecting 'الكل' yields no filter.
class _StatusFilter extends StatelessWidget {
  final TripsListLoaded state;
  const _StatusFilter({required this.state});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<OperationTripStatus?>(
      isExpanded: true,
      initialValue: state.statusFilter,
      decoration: const InputDecoration(labelText: 'الحالة'),
      items: [
        const DropdownMenuItem(value: null, child: Text('الكل')),
        ...OperationTripStatus.values.map(
          (status) => DropdownMenuItem(
            value: status,
            child: Text(status.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: context.read<TripsListCubit>().filterStatus,
    );
  }
}

/// Generic dropdown filter for strings.  Presents available values with
/// labels; selecting 'الكل' resets the filter.
class _StringFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _StringFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('الكل')),
        ...values.map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (next) => onChanged(next ?? ''),
    );
  }
}

/// The data table presenting the list of trips.  We use a horizontal
/// scroll view to accommodate narrow viewports and Flutter's `DataTable`
/// for built‑in semantics and accessibility.
class _TripsTable extends StatelessWidget {
  final TripsListLoaded listState;
  final ValueChanged<OperationTrip> onOpenTrip;
  final ValueChanged<OperationTrip> onDuplicateTrip;
  final ValueChanged<OperationTrip> onDeleteTrip;
  const _TripsTable({
    required this.listState,
    required this.onOpenTrip,
    required this.onDuplicateTrip,
    required this.onDeleteTrip,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                Text(
                  'قائمة الرحلات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${listState.filteredTrips.length} رحلة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (listState.filteredTrips.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Text(
                'لا توجد رحلات مطابقة للفلاتر الحالية',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                0,
                AppSpacing.medium,
                AppSpacing.medium,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1180
                      ? 3
                      : constraints.maxWidth >= 760
                      ? 2
                      : 1;
                  final detailsState = context.watch<TripDetailsCubit>().state;
                  final selectedId = detailsState is TripDetailsLoaded
                      ? detailsState.trip.id
                      : '';
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listState.filteredTrips.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.medium,
                      mainAxisSpacing: AppSpacing.medium,
                      mainAxisExtent: 260,
                    ),
                    itemBuilder: (context, index) {
                      final trip = listState.filteredTrips[index];
                      return _TripOperationCard(
                        trip: trip,
                        selected: selectedId == trip.id,
                        onOpen: () => onOpenTrip(trip),
                        onDuplicate: () => onDuplicateTrip(trip),
                        onDelete: () => onDeleteTrip(trip),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TripOperationCard extends StatelessWidget {
  final OperationTrip trip;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _TripOperationCard({
    required this.trip,
    required this.selected,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = _occupancyRatio(trip);
    final attention = _attentionLabel(trip);
    return Semantics(
      button: true,
      label:
          'الرحلة ${trip.id}، ${trip.route}، الحالة ${trip.status.label}، ${trip.bookedSeats} من ${trip.capacity} مقعد محجوز',
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusChip(
                      label: trip.status.label,
                      color: _statusColor(context, trip.status).withAlpha(28),
                      textColor: _statusColor(context, trip.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  trip.id
                      .substring(0, trip.id.length < 8 ? trip.id.length : 8)
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _CardFact(
                  icon: Icons.schedule_rounded,
                  label: 'المغادرة',
                  value: '${trip.date}  ${trip.departure}',
                ),
                const SizedBox(height: AppSpacing.xSmall),
                _CardFact(
                  icon: Icons.person_outline_rounded,
                  label: 'السائق',
                  value: trip.driver,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                _CardFact(
                  icon: Icons.directions_bus_rounded,
                  label: 'المركبة',
                  value: trip.vehicle,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _OccupancyBar(
                        ratio: occupancy,
                        label:
                            '${trip.bookedSeats}/${trip.capacity} محجوز - ${trip.availableSeats} متاح',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Tooltip(
                      message: 'نسخ الرحلة',
                      child: IconButton(
                        onPressed: onDuplicate,
                        icon: const Icon(Icons.copy_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Tooltip(
                      message: 'حذف الرحلة',
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: scheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Tooltip(
                      message: 'فتح مساحة تشغيل الرحلة',
                      child: IconButton.filledTonal(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new_rounded),
                      ),
                    ),
                  ],
                ),
                if (attention != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attention,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _WorkspaceOperationsHeader extends StatelessWidget {
  final OperationTrip trip;
  final ValueChanged<OperationTripStatus> onChangeStatus;
  final VoidCallback onClose;

  const _WorkspaceOperationsHeader({
    required this.trip,
    required this.onChangeStatus,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = _occupancyRatio(trip);
    final attention = _attentionLabel(trip);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  trip.route,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Text(
                    trip.id
                        .substring(0, trip.id.length < 8 ? trip.id.length : 8)
                        .toUpperCase(),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                PopupMenuButton<OperationTripStatus>(
                  tooltip: 'تغيير الحالة التشغيلية',
                  onSelected: onChangeStatus,
                  itemBuilder: (context) => OperationTripStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: StatusChip(
                      label: trip.status.label,
                      color: _statusColor(context, trip.status).withAlpha(28),
                      textColor: _statusColor(context, trip.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _TripInfoChip(
                  icon: Icons.schedule_rounded,
                  label: '${trip.date}  ${trip.departure}',
                ),
                _TripInfoChip(
                  icon: Icons.flag_outlined,
                  label: trip.arrival.isEmpty ? 'وصول غير محدد' : trip.arrival,
                ),
                _TripInfoChip(
                  icon: Icons.person_outline_rounded,
                  label: trip.driver,
                ),
                _TripInfoChip(
                  icon: Icons.directions_bus_rounded,
                  label: trip.vehicle,
                ),
              ],
            ),
            if (attention != null) ...[
              const SizedBox(height: AppSpacing.small),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attention,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
        final facts = Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            _WorkspaceMetric(
              label: 'الإشغال',
              value: '${(occupancy * 100).round()}%',
              icon: Icons.speed_rounded,
            ),
            _WorkspaceMetric(
              label: 'محجوز',
              value: '${trip.bookedSeats}/${trip.capacity}',
              icon: Icons.event_seat_rounded,
            ),
            _WorkspaceMetric(
              label: 'متاح',
              value: '${trip.availableSeats}',
              icon: Icons.check_circle_outline_rounded,
            ),
            _WorkspaceMetric(
              label: 'محظور',
              value: '${trip.blockedSeats}',
              icon: Icons.block_rounded,
            ),
            Tooltip(
              message: 'إغلاق مساحة تشغيل الرحلة',
              child: IconButton.filledTonal(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppSpacing.medium),
              _OccupancyBar(
                ratio: occupancy,
                label:
                    '${trip.bookedSeats}/${trip.capacity} مقعد مشغول - ${trip.availableSeats} متاح',
              ),
              const SizedBox(height: AppSpacing.medium),
              facts,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpacing.medium),
            SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _OccupancyBar(
                    ratio: occupancy,
                    label:
                        '${trip.bookedSeats}/${trip.capacity} مقعد مشغول - ${trip.availableSeats} متاح',
                  ),
                  const SizedBox(height: AppSpacing.small),
                  facts,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkspaceMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WorkspaceMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(55),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final double ratio;
  final String label;

  const _OccupancyBar({required this.ratio, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratio >= 0.9
        ? scheme.error
        : ratio >= 0.75
        ? scheme.tertiary
        : scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 8,
            color: color,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

/// The workspace for an individual trip.  This panel contains a header
/// summarising the trip and a set of tabs for different management
/// functions (overview, seats, passengers, pricing, etc.).  The
/// workspace is extracted into its own widget to keep the main view
/// simpler.
class _TripWorkspace extends StatelessWidget {
  final OperationTrip trip;
  const _TripWorkspace({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripDetailsCubit>();
    return BlocBuilder<TripDetailsCubit, TripDetailsState>(
      builder: (context, state) {
        if (state is! TripDetailsLoaded) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TripCommandHero(
              trip: state.trip,
              selectedTab: state.tab,
              saving: state.isSaving,
              onClose: cubit.closeDetails,
              onSelectTab: cubit.changeWorkspaceTab,
              onChangeStatus: (nextStatus) async {
                final updated = await cubit.updateStatus(nextStatus);
                if (updated != null && context.mounted) {
                  context.read<TripsListCubit>().updateTripInList(updated);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر تحديث حالة الرحلة. حاول مرة أخرى.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1060;
                final content = _TripWorkspaceContent(
                  trip: state.trip,
                  tab: state.tab,
                  onSelectTab: cubit.changeWorkspaceTab,
                );
                final side = _TripOperationsSidePanel(
                  trip: state.trip,
                  saving: state.isSaving,
                  onChangeStatus: (nextStatus) async {
                    final updated = await cubit.updateStatus(nextStatus);
                    if (updated != null && context.mounted) {
                      context.read<TripsListCubit>().updateTripInList(updated);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تعذر تحديث حالة الرحلة. حاول مرة أخرى.',
                          ),
                        ),
                      );
                    }
                  },
                  onSelectTab: cubit.changeWorkspaceTab,
                );
                if (!wide) {
                  return Column(
                    children: [
                      side,
                      const SizedBox(height: AppSpacing.medium),
                      content,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 340, child: side),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TripWorkspaceContent extends StatelessWidget {
  final OperationTrip trip;
  final TripWorkspaceTab tab;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _TripWorkspaceContent({
    required this.trip,
    required this.tab,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: _tabIcon(tab),
            title: _tabLabel(tab),
            subtitle: _tabSubtitle(tab),
          ),
          const SizedBox(height: AppSpacing.medium),
          switch (tab) {
            TripWorkspaceTab.overview => _OverviewTab(
              trip: trip,
              onSelectTab: onSelectTab,
            ),
            TripWorkspaceTab.passengers => _PassengersTab(
              trip: trip,
              onSelectTab: onSelectTab,
            ),
            TripWorkspaceTab.seats => _SeatsTab(
              trip: trip,
              onSelectTab: onSelectTab,
            ),
            TripWorkspaceTab.pricing => TripPricingTab(trip: trip),
            TripWorkspaceTab.payments => _PaymentsTab(
              trip: trip,
              onSelectTab: onSelectTab,
            ),
            TripWorkspaceTab.history => _HistoryTab(trip: trip),
          },
        ],
      ),
    );
  }
}

class _TripCommandHero extends StatelessWidget {
  final OperationTrip trip;
  final TripWorkspaceTab selectedTab;
  final bool saving;
  final VoidCallback onClose;
  final ValueChanged<TripWorkspaceTab> onSelectTab;
  final ValueChanged<OperationTripStatus> onChangeStatus;

  const _TripCommandHero({
    required this.trip,
    required this.selectedTab,
    required this.saving,
    required this.onClose,
    required this.onSelectTab,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, trip.status);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(18),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.xSmall,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          label: trip.status.label,
                          color: statusColor.withAlpha(34),
                          textColor: statusColor,
                        ),
                        _TripCodeBadge(id: trip.id),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      trip.route,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        _TripInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: trip.date,
                        ),
                        _TripInfoChip(
                          icon: Icons.schedule_rounded,
                          label: '${trip.departure} → ${trip.arrival}',
                        ),
                        _TripInfoChip(
                          icon: Icons.person_outline_rounded,
                          label: trip.driver,
                        ),
                        _TripInfoChip(
                          icon: Icons.directions_bus_rounded,
                          label: trip.vehicle,
                        ),
                      ],
                    ),
                  ],
                );
                final actions = Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    _PrimaryTripAction(
                      trip: trip,
                      saving: saving,
                      onChangeStatus: onChangeStatus,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.xSmall,
                      runSpacing: AppSpacing.xSmall,
                      alignment: compact
                          ? WrapAlignment.start
                          : WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              onSelectTab(TripWorkspaceTab.passengers),
                          icon: const Icon(Icons.people_outline_rounded),
                          label: const Text('الركاب'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => onSelectTab(TripWorkspaceTab.seats),
                          icon: const Icon(Icons.event_seat_outlined),
                          label: const Text('المقاعد'),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'إغلاق تفاصيل الرحلة',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.medium),
                      actions,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.large),
                    actions,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              AppSpacing.medium,
              AppSpacing.large,
              AppSpacing.large,
            ),
            child: Column(
              children: [
                _TripLifecycleRail(
                  status: trip.status,
                  saving: saving,
                  onChangeStatus: onChangeStatus,
                ),
                const SizedBox(height: AppSpacing.medium),
                _WorkspaceTabBar(
                  selected: selectedTab,
                  onSelected: onSelectTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripOperationsSidePanel extends StatelessWidget {
  final OperationTrip trip;
  final bool saving;
  final ValueChanged<OperationTripStatus> onChangeStatus;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _TripOperationsSidePanel({
    required this.trip,
    required this.saving,
    required this.onChangeStatus,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NextActionCard(
          trip: trip,
          saving: saving,
          onChangeStatus: onChangeStatus,
        ),
        const SizedBox(height: AppSpacing.medium),
        _OperationsReadinessCard(trip: trip, onSelectTab: onSelectTab),
        const SizedBox(height: AppSpacing.medium),
        _QuickJumpCard(onSelectTab: onSelectTab),
      ],
    );
  }
}

class _TripLifecycleRail extends StatelessWidget {
  final OperationTripStatus status;
  final bool saving;
  final ValueChanged<OperationTripStatus> onChangeStatus;

  const _TripLifecycleRail({
    required this.status,
    required this.saving,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = const [
      OperationTripStatus.scheduled,
      OperationTripStatus.openForBooking,
      OperationTripStatus.boarding,
      OperationTripStatus.inProgress,
      OperationTripStatus.completed,
    ];
    final currentIndex = statuses.indexOf(status);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: statuses.indexed.map((entry) {
            final (index, item) = entry;
            final reached = currentIndex >= index && currentIndex != -1;
            final current = item == status;
            return SizedBox(
              width: compact ? constraints.maxWidth : 150,
              child: _LifecycleStepChip(
                status: item,
                reached: reached,
                current: current,
                onTap: saving ? null : () => onChangeStatus(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LifecycleStepChip extends StatelessWidget {
  final OperationTripStatus status;
  final bool reached;
  final bool current;
  final VoidCallback? onTap;

  const _LifecycleStepChip({
    required this.status,
    required this.reached,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor(context, status);
    return Material(
      color: current
          ? color.withAlpha(32)
          : reached
          ? scheme.primaryContainer.withAlpha(50)
          : scheme.surfaceContainerHighest.withAlpha(55),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Row(
            children: [
              Icon(
                reached
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: current ? color : scheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: current ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceTabBar extends StatelessWidget {
  final TripWorkspaceTab selected;
  final ValueChanged<TripWorkspaceTab> onSelected;

  const _WorkspaceTabBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TripWorkspaceTab.values.map((tab) {
          final active = tab == selected;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
            child: ChoiceChip(
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onSelected(tab),
              avatar: Icon(
                _tabIcon(tab),
                size: 18,
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              label: Text(_tabLabel(tab)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrimaryTripAction extends StatelessWidget {
  final OperationTrip trip;
  final bool saving;
  final ValueChanged<OperationTripStatus> onChangeStatus;

  const _PrimaryTripAction({
    required this.trip,
    required this.saving,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(trip.status);
    if (next == null) {
      return StatusChip(label: _terminalStatusLabel(trip.status));
    }
    return FilledButton.icon(
      onPressed: saving ? null : () => onChangeStatus(next),
      icon: saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow_rounded),
      label: Text(saving ? 'جاري التحديث...' : _statusActionLabel(next)),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;
  final VoidCallback onTap;

  const _ReadinessRow({
    required this.label,
    required this.value,
    required this.ok,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
              color: ok ? scheme.primary : scheme.error,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(child: Text(label)),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCodeBadge extends StatelessWidget {
  final String id;

  const _TripCodeBadge({required this.id});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Text(
        id.substring(0, id.length < 8 ? id.length : 8).toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final OperationTrip trip;
  final bool saving;
  final ValueChanged<OperationTripStatus> onChangeStatus;

  const _NextActionCard({
    required this.trip,
    required this.saving,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(trip.status);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.play_circle_outline_rounded,
            title: 'الخطوة التالية',
            subtitle: _nextActionCopy(trip),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (next == null)
            StatusChip(label: 'لا توجد خطوة تشغيلية تالية')
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : () => onChangeStatus(next),
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  saving ? 'جاري التحديث...' : _statusActionLabel(next),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: saving || trip.status == OperationTripStatus.cancelled
                  ? null
                  : () => onChangeStatus(OperationTripStatus.cancelled),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('إلغاء الرحلة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsReadinessCard extends StatelessWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _OperationsReadinessCard({
    required this.trip,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final occupancy = _occupancyRatio(trip);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.health_and_safety_outlined,
            title: 'جاهزية التشغيل',
            subtitle: _attentionLabel(trip) ?? 'لا توجد تنبيهات حرجة حالياً',
          ),
          const SizedBox(height: AppSpacing.medium),
          _OccupancyBar(
            ratio: occupancy,
            label:
                '${trip.bookedSeats}/${trip.capacity} مشغول - ${trip.availableSeats} متاح',
          ),
          const SizedBox(height: AppSpacing.medium),
          _ReadinessRow(
            label: 'المقاعد',
            value: '${trip.seats.length}/${trip.capacity}',
            ok: trip.seats.length >= trip.capacity && trip.capacity > 0,
            onTap: () => onSelectTab(TripWorkspaceTab.seats),
          ),
          _ReadinessRow(
            label: 'الركاب',
            value: '${trip.passengers.length}',
            ok: trip.passengers.length <= trip.capacity,
            onTap: () => onSelectTab(TripWorkspaceTab.passengers),
          ),
          _ReadinessRow(
            label: 'المحطات',
            value: '${trip.routePoints.length}',
            ok: trip.routePoints.length >= 2,
            onTap: () => onSelectTab(TripWorkspaceTab.overview),
          ),
          _ReadinessRow(
            label: 'السعر',
            value: '${trip.ticketPrice.toStringAsFixed(0)} ${trip.currency}',
            ok: trip.ticketPrice > 0,
            onTap: () => onSelectTab(TripWorkspaceTab.pricing),
          ),
        ],
      ),
    );
  }
}

class _QuickJumpCard extends StatelessWidget {
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _QuickJumpCard({required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.touch_app_outlined,
            title: 'اختصارات الإدارة',
            subtitle: 'انتقل مباشرة للقسم المطلوب',
          ),
          const SizedBox(height: AppSpacing.medium),
          for (final tab in TripWorkspaceTab.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onSelectTab(tab),
                  icon: Icon(_tabIcon(tab)),
                  label: Text(_tabLabel(tab)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TripInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _OverviewTab({required this.trip, required this.onSelectTab});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstStop = trip.routePoints.isEmpty
        ? 'غير محدد'
        : trip.routePoints.first.name;
    final lastStop = trip.routePoints.isEmpty
        ? 'غير محدد'
        : trip.routePoints.last.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            final cards = <Widget>[
              _OperationsSnapshotCard(
                title: 'المسار',
                value: '$firstStop ← $lastStop',
                icon: Icons.alt_route_rounded,
                supporting: '${trip.routePoints.length} محطات',
              ),
              _OperationsSnapshotCard(
                title: 'الجدولة',
                value: '${trip.date}  ${trip.departure}',
                icon: Icons.schedule_rounded,
                supporting:
                    'الوصول: ${trip.arrival.isEmpty ? 'غير محدد' : trip.arrival}',
              ),
              _OperationsSnapshotCard(
                title: 'الطاقم',
                value: trip.driver,
                icon: Icons.person_outline_rounded,
                supporting: trip.vehicle,
              ),
              _OperationsSnapshotCard(
                title: 'الإشغال',
                value: '${trip.bookedSeats}/${trip.capacity}',
                icon: Icons.event_seat_rounded,
                supporting:
                    '${trip.availableSeats} متاح - ${trip.blockedSeats} محظور',
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
                mainAxisExtent: 104,
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        _TripDetailHealthPanel(trip: trip, onSelectTab: onSelectTab),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مسار التشغيل',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'نقاط التوقف مرتبة لتسهيل متابعة الصعود والنزول أثناء التشغيل.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.medium),
              _RouteTimelineStrip(trip: trip),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripDetailHealthPanel extends StatelessWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _TripDetailHealthPanel({required this.trip, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final items = [
          _DetailHealthItem(
            icon: Icons.event_seat_outlined,
            title: 'المقاعد',
            value: '${trip.seats.length}/${trip.capacity}',
            subtitle: trip.seats.length >= trip.capacity && trip.capacity > 0
                ? 'التوزيع مكتمل'
                : 'راجع توليد المقاعد والسعة',
            ok: trip.seats.length >= trip.capacity && trip.capacity > 0,
            onTap: () => onSelectTab(TripWorkspaceTab.seats),
          ),
          _DetailHealthItem(
            icon: Icons.payments_outlined,
            title: 'التسعير الأساسي',
            value: trip.ticketPrice > 0
                ? '${trip.ticketPrice.toStringAsFixed(0)} ${trip.currency}'
                : 'غير محدد',
            subtitle: trip.ticketPrice > 0
                ? 'جاهز للحجز'
                : 'أضف سعر الرحلة قبل فتح الحجوزات',
            ok: trip.ticketPrice > 0,
            onTap: () => onSelectTab(TripWorkspaceTab.pricing),
          ),
          _DetailHealthItem(
            icon: Icons.route_outlined,
            title: 'المسار',
            value: '${trip.routePoints.length} محطات',
            subtitle: trip.routePoints.length >= 2
                ? 'نقاط الصعود والنزول متاحة'
                : 'المسار يحتاج نقطتين على الأقل',
            ok: trip.routePoints.length >= 2,
            onTap: () => onSelectTab(TripWorkspaceTab.overview),
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}

class _DetailHealthItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool ok;
  final VoidCallback onTap;

  const _DetailHealthItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.ok,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? scheme.primary : scheme.error;
    return Material(
      color: color.withAlpha(ok ? 14 : 18),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: color.withAlpha(55)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsSnapshotCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String supporting;

  const _OperationsSnapshotCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.supporting,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.small),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            supporting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RouteTimelineStrip extends StatelessWidget {
  final OperationTrip trip;

  const _RouteTimelineStrip({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (trip.routePoints.isEmpty) {
      return Text(
        'لا توجد نقاط مسار مرتبطة بهذه الرحلة.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    return _HorizontalScroll(
      child: Row(
        children: trip.routePoints.map((point) {
          final isFirst = point == trip.routePoints.first;
          final isLast = point == trip.routePoints.last;
          return Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 132),
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: isFirst || isLast
                      ? scheme.primaryContainer.withAlpha(70)
                      : scheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(
                    color: isFirst || isLast
                        ? scheme.primary.withAlpha(90)
                        : scheme.outline.withAlpha(60),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${point.order}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      point.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFirst
                          ? 'مغادرة ${trip.departure}'
                          : isLast
                          ? 'وصول ${trip.arrival.isEmpty ? 'متوقع' : trip.arrival}'
                          : 'توقف وسيط',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PassengersTab extends StatefulWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _PassengersTab({required this.trip, required this.onSelectTab});

  @override
  State<_PassengersTab> createState() => _PassengersTabState();
}

class _PassengersTabState extends State<_PassengersTab> {
  String _query = '';
  String _status = 'الكل';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trip = widget.trip;
    final headers = const [
      'الاسم',
      'الهاتف',
      'المقعد',
      'نقطة الصعود',
      'نقطة النزول',
      'طريقة الدفع',
      'الحالة',
      'الإجراءات',
    ];
    final statuses = ['الكل', ...trip.passengers.map((p) => p.status).toSet()];
    final filteredPassengers = trip.passengers.where((passenger) {
      final query = _query.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          passenger.name.toLowerCase().contains(query) ||
          passenger.phone.toLowerCase().contains(query) ||
          passenger.seat.toLowerCase().contains(query) ||
          passenger.pickup.toLowerCase().contains(query) ||
          passenger.dropoff.toLowerCase().contains(query);
      final matchesStatus = _status == 'الكل' || passenger.status == _status;
      return matchesSearch && matchesStatus;
    }).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              0,
            ),
            child: _PassengerManifestSummary(
              trip: trip,
              onSelectSeats: () => widget.onSelectTab(TripWorkspaceTab.seats),
              onSelectPayments: () =>
                  widget.onSelectTab(TripWorkspaceTab.payments),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final search = SizedBox(
                  width: compact ? constraints.maxWidth : 360,
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      labelText: 'بحث بالراكب، الهاتف، المقعد أو المحطة',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                );
                final status = SizedBox(
                  width: compact ? constraints.maxWidth : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'حالة الراكب'),
                    items: statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'الكل'),
                  ),
                );
                return Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    search,
                    status,
                    StatusChip(
                      label: '${filteredPassengers.length} راكب',
                      color: scheme.primary.withAlpha(22),
                      textColor: scheme.primary,
                    ),
                  ],
                );
              },
            ),
          ),
          if (trip.passengers.isEmpty)
            _ManifestEmptyState(
              color: scheme.onSurfaceVariant,
              onSelectSeats: () => widget.onSelectTab(TripWorkspaceTab.seats),
              onSelectPricing: () =>
                  widget.onSelectTab(TripWorkspaceTab.pricing),
            )
          else if (filteredPassengers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Text(
                'لا يوجد ركاب مطابقون للبحث أو الفلتر الحالي.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 820) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      0,
                      AppSpacing.medium,
                      AppSpacing.medium,
                    ),
                    child: Column(
                      children: filteredPassengers
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.small,
                              ),
                              child: _PassengerManifestCard(
                                trip: trip,
                                passenger: p,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                }
                return _HorizontalScroll(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 980),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        scheme.surfaceContainerHighest.withAlpha(90),
                      ),
                      columns: headers
                          .map((h) => DataColumn(label: Text(h)))
                          .toList(),
                      rows: filteredPassengers.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(p.phone)),
                            DataCell(_SeatBadge(label: p.seat)),
                            DataCell(Text(p.pickup)),
                            DataCell(Text(p.dropoff)),
                            DataCell(Text(p.paymentMethod)),
                            DataCell(StatusChip(label: p.status)),
                            DataCell(
                              _PassengerActions(trip: trip, passenger: p),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PassengerManifestSummary extends StatelessWidget {
  final OperationTrip trip;
  final VoidCallback onSelectSeats;
  final VoidCallback onSelectPayments;

  const _PassengerManifestSummary({
    required this.trip,
    required this.onSelectSeats,
    required this.onSelectPayments,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paid = trip.passengers
        .where((p) => _paymentBucket(p) == _PaymentBucket.paid)
        .length;
    final pending = trip.passengers
        .where((p) => _paymentBucket(p) == _PaymentBucket.pending)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 4 : 2;
        final items = [
          _CompactOpsMetric(
            label: 'الركاب',
            value: '${trip.passengers.length}',
            icon: Icons.people_outline_rounded,
            color: scheme.primary,
          ),
          _CompactOpsMetric(
            label: 'المقاعد المتاحة',
            value: '${trip.availableSeats}',
            icon: Icons.event_available_outlined,
            color: scheme.secondary,
            onTap: onSelectSeats,
          ),
          _CompactOpsMetric(
            label: 'مدفوع',
            value: '$paid',
            icon: Icons.check_circle_outline_rounded,
            color: scheme.primary,
            onTap: onSelectPayments,
          ),
          _CompactOpsMetric(
            label: 'معلق',
            value: '$pending',
            icon: Icons.pending_actions_rounded,
            color: scheme.tertiary,
            onTap: onSelectPayments,
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.small,
            mainAxisSpacing: AppSpacing.small,
            mainAxisExtent: 78,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}

class _ManifestEmptyState extends StatelessWidget {
  final Color color;
  final VoidCallback onSelectSeats;
  final VoidCallback onSelectPricing;

  const _ManifestEmptyState({
    required this.color,
    required this.onSelectSeats,
    required this.onSelectPricing,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionEmptyState(
      icon: Icons.people_outline_rounded,
      title: 'لا يوجد ركاب على هذه الرحلة',
      message:
          'بعد فتح الرحلة للحجز ستظهر الحجوزات هنا. قبل ذلك تأكد أن المقاعد والتسعير جاهزان.',
      actions: [
        OutlinedButton.icon(
          onPressed: onSelectSeats,
          icon: const Icon(Icons.event_seat_outlined),
          label: const Text('مراجعة المقاعد'),
        ),
        FilledButton.tonalIcon(
          onPressed: onSelectPricing,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('مراجعة التسعير'),
        ),
      ],
    );
  }
}

class _CompactOpsMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CompactOpsMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: color.withAlpha(45)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  const _ActionEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(35),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary, size: 28),
            const SizedBox(height: AppSpacing.small),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PassengerManifestCard extends StatelessWidget {
  final OperationTrip trip;
  final TripPassenger passenger;

  const _PassengerManifestCard({required this.trip, required this.passenger});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SeatBadge(label: passenger.seat),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  passenger.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _PassengerActions(trip: trip, passenger: passenger),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              _TripInfoChip(icon: Icons.phone_outlined, label: passenger.phone),
              _TripInfoChip(icon: Icons.login_rounded, label: passenger.pickup),
              _TripInfoChip(
                icon: Icons.logout_rounded,
                label: passenger.dropoff,
              ),
              _TripInfoChip(
                icon: Icons.payments_outlined,
                label: passenger.paymentMethod,
              ),
              StatusChip(label: passenger.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerActions extends StatelessWidget {
  final OperationTrip trip;
  final TripPassenger passenger;

  const _PassengerActions({required this.trip, required this.passenger});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات الراكب',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _openPassengerDialog(context, trip, passenger);
          case 'move':
            _openMoveDialog(context, trip, passenger);
          case 'cancel':
            context.read<TripPassengersCubit>().cancelBooking(
              trip.id,
              passenger.id,
            );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
        PopupMenuItem(value: 'move', child: Text('نقل المقعد')),
        PopupMenuItem(value: 'cancel', child: Text('إلغاء الحجز')),
      ],
    );
  }
}

class _SeatBadge extends StatelessWidget {
  final String label;

  const _SeatBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SeatsTab extends StatefulWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _SeatsTab({required this.trip, required this.onSelectTab});

  @override
  State<_SeatsTab> createState() => _SeatsTabState();
}

class _SeatsTabState extends State<_SeatsTab> {
  TripSeatState? _filter;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final scheme = Theme.of(context).colorScheme;
    final occupancy = _occupancyRatio(trip);
    final sortedSeats = [...trip.seats]
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        return rowCompare == 0 ? a.column.compareTo(b.column) : rowCompare;
      });
    final visibleSeats = _filter == null
        ? sortedSeats
        : sortedSeats.where((seat) => seat.state == _filter).toList();
    final columns = trip.seats.isEmpty
        ? 4
        : trip.seats.map((seat) => seat.column).reduce((a, b) => a > b ? a : b);
    final seatColumns = columns.clamp(3, 6);
    final passengerBySeat = {
      for (final passenger in trip.passengers) passenger.seat: passenger,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة المقاعد',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _OccupancyBar(
                        ratio: occupancy,
                        label:
                            '${trip.bookedSeats}/${trip.capacity} مقعد مشغول - ${trip.availableSeats} متاح',
                      ),
                    ],
                  );
                  final actions = Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            widget.onSelectTab(TripWorkspaceTab.passengers),
                        icon: const Icon(Icons.people_outline_rounded),
                        label: const Text('قائمة الركاب'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            widget.onSelectTab(TripWorkspaceTab.payments),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('المدفوعات'),
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        summary,
                        const SizedBox(height: AppSpacing.medium),
                        actions,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: AppSpacing.large),
                      actions,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              _SeatMetricsGrid(trip: trip),
              if (trip.seats.length != trip.capacity && trip.capacity > 0) ...[
                const SizedBox(height: AppSpacing.medium),
                _InlineOpsNotice(
                  icon: Icons.warning_amber_rounded,
                  message:
                      'عدد المقاعد المسجلة (${trip.seats.length}) لا يطابق سعة المركبة (${trip.capacity}). راجع إعداد الرحلة أو المركبة قبل فتح الحجز.',
                  color: scheme.error,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مخطط المقاعد',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'استخدم الفلاتر للتركيز على حالة معينة. انقر على أي مقعد لتغيير حالته أو مراجعة الراكب المرتبط.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.medium),
              _SeatStateFilterBar(
                selected: _filter,
                onSelected: (state) => setState(() => _filter = state),
                trip: trip,
              ),
              const SizedBox(height: AppSpacing.medium),
              BlocBuilder<TripSeatsCubit, TripSeatsState>(
                builder: (context, state) {
                  if (state is TripSeatsLoading) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }
                  if (state is TripSeatsError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: _InlineOpsNotice(
                        icon: Icons.error_outline_rounded,
                        message: state.message,
                        color: scheme.error,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (trip.seats.isEmpty)
                _ActionEmptyState(
                  icon: Icons.event_seat_outlined,
                  title: 'لا توجد مقاعد مولدة لهذه الرحلة',
                  message:
                      'يجب أن تحتوي الرحلة على مقاعد مرتبطة بالمركبة حتى يتمكن العملاء من الحجز ويتضح توزيع السعة.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          widget.onSelectTab(TripWorkspaceTab.overview),
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('مراجعة الرحلة'),
                    ),
                  ],
                )
              else if (visibleSeats.isEmpty)
                _ActionEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'لا توجد مقاعد بهذا الفلتر',
                  message: 'غيّر الفلتر لعرض باقي المقاعد في هذه الرحلة.',
                  actions: [
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _filter = null),
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('عرض كل المقاعد'),
                    ),
                  ],
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth =
                        ((constraints.maxWidth -
                                    (seatColumns - 1) * AppSpacing.small) /
                                seatColumns)
                            .clamp(58.0, 92.0);
                    final mapWidth =
                        tileWidth * seatColumns +
                        (seatColumns - 1) * AppSpacing.small;
                    return _HorizontalScroll(
                      child: SizedBox(
                        width: mapWidth,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: tileWidth,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: scheme.outline.withAlpha(35),
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusSmall,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'السائق',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.directions_bus_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.medium),
                            const Divider(),
                            const SizedBox(height: AppSpacing.medium),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleSeats.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: seatColumns,
                                    crossAxisSpacing: AppSpacing.small,
                                    mainAxisSpacing: AppSpacing.small,
                                    mainAxisExtent: 76,
                                  ),
                              itemBuilder: (context, index) {
                                final seat = visibleSeats[index];
                                return _SeatTile(
                                  trip: trip,
                                  seat: seat,
                                  passenger: passengerBySeat[seat.label],
                                  cubit: context.read<TripSeatsCubit>(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeatMetricsGrid extends StatelessWidget {
  final OperationTrip trip;

  const _SeatMetricsGrid({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 5
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        final items = [
          _CompactOpsMetric(
            label: 'متاح',
            value: '${trip.availableSeats}',
            icon: Icons.event_available_outlined,
            color: _seatColor(context, TripSeatState.available),
          ),
          _CompactOpsMetric(
            label: 'محجوز',
            value: '${_seatCount(trip, TripSeatState.reserved)}',
            icon: Icons.bookmark_added_outlined,
            color: _seatColor(context, TripSeatState.reserved),
          ),
          _CompactOpsMetric(
            label: 'مدفوع',
            value: '${_seatCount(trip, TripSeatState.paid)}',
            icon: Icons.verified_outlined,
            color: _seatColor(context, TripSeatState.paid),
          ),
          _CompactOpsMetric(
            label: 'اشتراك',
            value: '${_seatCount(trip, TripSeatState.subscription)}',
            icon: Icons.card_membership_outlined,
            color: _seatColor(context, TripSeatState.subscription),
          ),
          _CompactOpsMetric(
            label: 'محظور',
            value: '${trip.blockedSeats}',
            icon: Icons.block_outlined,
            color: scheme.error,
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.small,
            mainAxisSpacing: AppSpacing.small,
            mainAxisExtent: 78,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}

class _SeatStateFilterBar extends StatelessWidget {
  final TripSeatState? selected;
  final ValueChanged<TripSeatState?> onSelected;
  final OperationTrip trip;

  const _SeatStateFilterBar({
    required this.selected,
    required this.onSelected,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        ChoiceChip(
          selected: selected == null,
          showCheckmark: false,
          avatar: Icon(
            Icons.apps_rounded,
            size: 18,
            color: selected == null ? scheme.onPrimary : scheme.primary,
          ),
          label: Text('الكل (${trip.seats.length})'),
          onSelected: (_) => onSelected(null),
        ),
        for (final state in TripSeatState.values)
          ChoiceChip(
            selected: selected == state,
            showCheckmark: false,
            avatar: Icon(
              _seatStateIcon(state),
              size: 18,
              color: selected == state
                  ? scheme.onPrimary
                  : _seatColor(context, state),
            ),
            label: Text('${state.label} (${_seatCount(trip, state)})'),
            onSelected: (_) => onSelected(state),
          ),
      ],
    );
  }
}

class _InlineOpsNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InlineOpsNotice({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final OperationTrip trip;
  final TripSeat seat;
  final TripPassenger? passenger;
  final TripSeatsCubit cubit;

  const _SeatTile({
    required this.trip,
    required this.seat,
    required this.passenger,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _seatColor(context, seat.state);
    return Semantics(
      button: true,
      label: 'المقعد ${seat.label}، الحالة ${seat.state.label}',
      child: Tooltip(
        message: passenger == null
            ? 'المقعد ${seat.label}: ${seat.state.label}'
            : 'المقعد ${seat.label}: ${passenger!.name}',
        child: InkWell(
          onTap: () => _openSeatStateDialog(
            context,
            trip,
            seat,
            cubit,
            passenger: passenger,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  seat.state == TripSeatState.available
                      ? Icons.airline_seat_recline_normal
                      : _seatStateIcon(seat.state),
                  size: 18,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  seat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (passenger != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    passenger!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: color, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final OperationTrip trip;
  final ValueChanged<TripWorkspaceTab> onSelectTab;

  const _PaymentsTab({required this.trip, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paid = trip.passengers
        .where((p) => _paymentBucket(p) == _PaymentBucket.paid)
        .length;
    final pending = trip.passengers
        .where((p) => _paymentBucket(p) == _PaymentBucket.pending)
        .length;
    final refunded = trip.passengers
        .where((p) => _paymentBucket(p) == _PaymentBucket.refunded)
        .length;
    final total = trip.passengers.length;
    final collectionRate = total == 0 ? 0.0 : paid / total;
    final estimatedCollected = paid * trip.ticketPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final summary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملخص التحصيل',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _OccupancyBar(
                    ratio: collectionRate,
                    label:
                        '$paid من $total مدفوع - تقديري ${estimatedCollected.toStringAsFixed(0)} ${trip.currency}',
                  ),
                ],
              );
              final actions = Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onSelectTab(TripWorkspaceTab.passengers),
                    icon: const Icon(Icons.people_outline_rounded),
                    label: const Text('الركاب'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => onSelectTab(TripWorkspaceTab.pricing),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('التسعير'),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summary,
                    const SizedBox(height: AppSpacing.medium),
                    actions,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: AppSpacing.large),
                  actions,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            final cards = [
              _PaymentSummaryCard(
                label: 'إجمالي الركاب',
                value: '$total',
                icon: Icons.people_outline_rounded,
                color: scheme.primary,
              ),
              _PaymentSummaryCard(
                label: 'مدفوع',
                value: '$paid',
                icon: Icons.check_circle_outline_rounded,
                color: scheme.primary,
              ),
              _PaymentSummaryCard(
                label: 'معلق',
                value: '$pending',
                icon: Icons.pending_actions_rounded,
                color: scheme.tertiary,
              ),
              _PaymentSummaryCard(
                label: 'مسترد',
                value: '$refunded',
                icon: Icons.undo_rounded,
                color: scheme.error,
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
                mainAxisExtent: 92,
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل التحصيل حسب الراكب',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'يعرض هذا القسم حالة الدفع المتاحة حالياً من بيانات الركاب والحجوزات المرتبطة بالرحلة.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (trip.passengers.isEmpty)
                _ActionEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد مدفوعات بعد',
                  message:
                      'ستظهر حالة التحصيل بعد وصول أول حجز. يمكنك مراجعة المقاعد والتسعير قبل فتح الرحلة للحجز.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => onSelectTab(TripWorkspaceTab.seats),
                      icon: const Icon(Icons.event_seat_outlined),
                      label: const Text('المقاعد'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => onSelectTab(TripWorkspaceTab.pricing),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('التسعير'),
                    ),
                  ],
                )
              else
                ...trip.passengers.map(
                  (passenger) => _PaymentPassengerRow(passenger: passenger),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PaymentSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PaymentPassengerRow extends StatelessWidget {
  final TripPassenger passenger;

  const _PaymentPassengerRow({required this.passenger});

  @override
  Widget build(BuildContext context) {
    final bucket = _paymentBucket(passenger);
    final scheme = Theme.of(context).colorScheme;
    final color = switch (bucket) {
      _PaymentBucket.paid => scheme.primary,
      _PaymentBucket.pending => scheme.tertiary,
      _PaymentBucket.refunded => scheme.error,
    };
    final label = switch (bucket) {
      _PaymentBucket.paid => 'مدفوع',
      _PaymentBucket.pending => 'معلق',
      _PaymentBucket.refunded => 'مسترد',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          _SeatBadge(label: passenger.seat),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  passenger.paymentMethod,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: label,
            color: color.withAlpha(32),
            textColor: color,
          ),
        ],
      ),
    );
  }
}

enum _PaymentBucket { paid, pending, refunded }

_PaymentBucket _paymentBucket(TripPassenger passenger) {
  final text = '${passenger.status} ${passenger.paymentMethod}'.toLowerCase();
  if (text.contains('refund') ||
      text.contains('مسترد') ||
      text.contains('مرتجع')) {
    return _PaymentBucket.refunded;
  }
  if (text.contains('pending') ||
      text.contains('معلق') ||
      text.contains('غير') ||
      text.contains('انتظار')) {
    return _PaymentBucket.pending;
  }
  return _PaymentBucket.paid;
}

class _HistoryTab extends StatelessWidget {
  final OperationTrip trip;
  const _HistoryTab({required this.trip});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (trip.events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LifecycleStatusSummary(trip: trip),
          const SizedBox(height: AppSpacing.medium),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: _ActionEmptyState(
              icon: Icons.history_rounded,
              title: 'لا توجد أحداث تشغيل مسجلة بعد',
              message:
                  'سيظهر هنا سجل تحديثات الرحلة عند بدء التشغيل أو عند تسجيل أحداث من النظام والتطبيقات المرتبطة.',
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LifecycleStatusSummary(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل التشغيل',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.medium),
              ...trip.events.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final isLast = index == trip.events.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          event.done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: event.done ? scheme.primary : scheme.tertiary,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 54,
                            color: scheme.outline.withAlpha(50),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.medium,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(35),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            border: Border.all(
                              color: scheme.outline.withAlpha(45),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    event.time,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(event.description),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _LifecycleStatusSummary extends StatelessWidget {
  final OperationTrip trip;

  const _LifecycleStatusSummary({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final doneEvents = trip.events.where((event) => event.done).length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالة السجل',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                '${trip.status.label} - ${trip.events.length} أحداث - $doneEvents مكتمل',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          );
          final chips = Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              StatusChip(label: trip.status.label),
              StatusChip(label: '${trip.passengers.length} ركاب'),
              StatusChip(label: '${trip.bookedSeats}/${trip.capacity} مقاعد'),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: AppSpacing.medium),
                chips,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: AppSpacing.medium),
              chips,
            ],
          );
        },
      ),
    );
  }
}

double _occupancyRatio(OperationTrip trip) {
  if (trip.capacity <= 0) return 0;
  return (trip.bookedSeats / trip.capacity).clamp(0, 1).toDouble();
}

String? _attentionLabel(OperationTrip trip) {
  if (trip.status == OperationTripStatus.cancelled) {
    return 'رحلة ملغاة';
  }
  if (trip.availableSeats == 0 && trip.capacity > 0) {
    return 'لا توجد مقاعد متاحة';
  }
  if (trip.blockedSeats > 0) {
    return '${trip.blockedSeats} مقاعد محظورة';
  }
  if (_occupancyRatio(trip) >= 0.85) {
    return 'الإشغال مرتفع';
  }
  return null;
}

Color _statusColor(BuildContext context, OperationTripStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    OperationTripStatus.completed => scheme.primary,
    OperationTripStatus.inProgress => scheme.tertiary,
    OperationTripStatus.boarding => scheme.tertiary,
    OperationTripStatus.cancelled => scheme.error,
    OperationTripStatus.openForBooking => scheme.secondary,
    OperationTripStatus.scheduled => scheme.primary,
  };
}

String _tabLabel(TripWorkspaceTab tab) {
  return switch (tab) {
    TripWorkspaceTab.overview => 'نظرة عامة',
    TripWorkspaceTab.passengers => 'الركاب',
    TripWorkspaceTab.seats => 'المقاعد',
    TripWorkspaceTab.pricing => 'التسعير',
    TripWorkspaceTab.payments => 'المدفوعات',
    TripWorkspaceTab.history => 'السجل',
  };
}

String _tabSubtitle(TripWorkspaceTab tab) {
  return switch (tab) {
    TripWorkspaceTab.overview => 'ملخص التشغيل والمسار والطاقم',
    TripWorkspaceTab.passengers => 'إدارة manifest الركاب والحجوزات',
    TripWorkspaceTab.seats => 'تعديل حالة المقاعد وتوزيع السعة',
    TripWorkspaceTab.pricing => 'ضبط أسعار شرائح الرحلة',
    TripWorkspaceTab.payments => 'متابعة حالة التحصيل والتوثيق',
    TripWorkspaceTab.history => 'سجل الأحداث والتغييرات التشغيلية',
  };
}

IconData _tabIcon(TripWorkspaceTab tab) {
  return switch (tab) {
    TripWorkspaceTab.overview => Icons.dashboard_outlined,
    TripWorkspaceTab.passengers => Icons.people_outline_rounded,
    TripWorkspaceTab.seats => Icons.event_seat_outlined,
    TripWorkspaceTab.pricing => Icons.payments_outlined,
    TripWorkspaceTab.payments => Icons.receipt_long_outlined,
    TripWorkspaceTab.history => Icons.history_rounded,
  };
}

OperationTripStatus? _nextStatus(OperationTripStatus status) {
  return switch (status) {
    OperationTripStatus.scheduled => OperationTripStatus.openForBooking,
    OperationTripStatus.openForBooking => OperationTripStatus.boarding,
    OperationTripStatus.boarding => OperationTripStatus.inProgress,
    OperationTripStatus.inProgress => OperationTripStatus.completed,
    OperationTripStatus.completed => null,
    OperationTripStatus.cancelled => null,
  };
}

String _statusActionLabel(OperationTripStatus next) {
  return switch (next) {
    OperationTripStatus.openForBooking => 'فتح للحجز',
    OperationTripStatus.boarding => 'بدء صعود الركاب',
    OperationTripStatus.inProgress => 'بدء الرحلة',
    OperationTripStatus.completed => 'إنهاء الرحلة',
    OperationTripStatus.scheduled => 'إرجاع لجدولة',
    OperationTripStatus.cancelled => 'إلغاء الرحلة',
  };
}

String _nextActionCopy(OperationTrip trip) {
  return switch (trip.status) {
    OperationTripStatus.scheduled =>
      'راجع المقاعد والتسعير ثم افتح الرحلة للحجز.',
    OperationTripStatus.openForBooking =>
      'تابع الحجوزات وجهز مرحلة صعود الركاب.',
    OperationTripStatus.boarding =>
      'راقب manifest الركاب ثم ابدأ الرحلة عند اكتمال الصعود.',
    OperationTripStatus.inProgress =>
      'تابع التشغيل الحي وأغلق الرحلة عند الوصول.',
    OperationTripStatus.completed => 'الرحلة مكتملة وجاهزة للمراجعة.',
    OperationTripStatus.cancelled => 'الرحلة ملغاة ولا توجد إجراءات تشغيلية.',
  };
}

String _terminalStatusLabel(OperationTripStatus status) {
  return switch (status) {
    OperationTripStatus.completed => 'الرحلة مكتملة',
    OperationTripStatus.cancelled => 'الرحلة ملغاة',
    _ => 'لا توجد خطوة تالية',
  };
}

Color _seatColor(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.primary,
    TripSeatState.reserved => scheme.tertiary,
    TripSeatState.paid => scheme.secondary,
    TripSeatState.subscription => scheme.primary,
    TripSeatState.blocked => scheme.error,
  };
}

IconData _seatStateIcon(TripSeatState state) {
  return switch (state) {
    TripSeatState.available => Icons.airline_seat_recline_normal,
    TripSeatState.reserved => Icons.bookmark_added_outlined,
    TripSeatState.paid => Icons.verified_outlined,
    TripSeatState.subscription => Icons.card_membership_outlined,
    TripSeatState.blocked => Icons.block_outlined,
  };
}

int _seatCount(OperationTrip trip, TripSeatState state) {
  return trip.seats.where((seat) => seat.state == state).length;
}

// Modal dialogs are reused from the original file without changes.

void _openPassengerDialog(
  BuildContext context,
  OperationTrip trip,
  TripPassenger passenger,
) {
  final name = TextEditingController(text: passenger.name);
  final phone = TextEditingController(text: passenger.phone);
  final pickup = TextEditingController(text: passenger.pickup);
  final dropoff = TextEditingController(text: passenger.dropoff);
  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تعديل راكب'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 480.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: pickup,
                decoration: const InputDecoration(labelText: 'نقطة الصعود'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: dropoff,
                decoration: const InputDecoration(labelText: 'نقطة النزول'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TripPassengersCubit>().editPassenger(
                trip.id,
                passenger.copyWith(
                  name: name.text,
                  phone: phone.text,
                  pickup: pickup.text,
                  dropoff: dropoff.text,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
}

void _openMoveDialog(
  BuildContext context,
  OperationTrip trip,
  TripPassenger passenger,
) {
  final available = trip.seats
      .where((seat) => seat.state == TripSeatState.available)
      .toList();
  var selected = available.isEmpty ? '' : available.first.label;
  var error = '';
  showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نقل لمقعد آخر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected.isEmpty ? null : selected,
                decoration: const InputDecoration(labelText: 'المقعد الجديد'),
                items: available
                    .map(
                      (seat) => DropdownMenuItem(
                        value: seat.label,
                        child: Text(seat.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => selected = v ?? selected,
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final cubit = context.read<TripPassengersCubit>();
                final result = await cubit.relocatePassenger(
                  trip.id,
                  passenger.id,
                  selected,
                );
                if (result == null) {
                  final s = cubit.state;
                  setState(
                    () => error = s is TripPassengersError
                        ? s.message
                        : 'تعذر نقل الراكب',
                  );
                  return;
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('نقل'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openSeatStateDialog(
  BuildContext context,
  OperationTrip trip,
  TripSeat seat,
  TripSeatsCubit cubit, {
  TripPassenger? passenger,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('المقعد ${seat.label}'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 520.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SeatDialogHeader(seat: seat, passenger: passenger),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'تغيير حالة المقعد',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: TripSeatState.values
                    .map(
                      (state) => FilledButton.tonalIcon(
                        onPressed: state == seat.state
                            ? null
                            : () {
                                cubit.changeSeatState(trip.id, seat.id, state);
                                Navigator.of(dialogContext).pop();
                              },
                        icon: Icon(_seatStateIcon(state)),
                        label: Text(state.label),
                      ),
                    )
                    .toList(),
              ),
              if (passenger != null &&
                  (seat.state == TripSeatState.paid ||
                      seat.state == TripSeatState.subscription ||
                      seat.state == TripSeatState.reserved)) ...[
                const SizedBox(height: AppSpacing.medium),
                _InlineOpsNotice(
                  icon: Icons.info_outline_rounded,
                  message:
                      'هذا المقعد مرتبط بالراكب ${passenger.name}. تغيير الحالة لا ينقل الراكب؛ استخدم نقل المقعد من تبويب الركاب عند الحاجة.',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(dialogContext).pop,
            child: const Text('إغلاق'),
          ),
        ],
      ),
    ),
  );
}

class _SeatDialogHeader extends StatelessWidget {
  final TripSeat seat;
  final TripPassenger? passenger;

  const _SeatDialogHeader({required this.seat, required this.passenger});

  @override
  Widget build(BuildContext context) {
    final color = _seatColor(context, seat.state);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Row(
        children: [
          Icon(_seatStateIcon(seat.state), color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seat.state.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  passenger == null
                      ? 'لا يوجد راكب مرتبط بهذا المقعد'
                      : '${passenger!.name} - ${passenger!.phone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _HorizontalScroll extends StatefulWidget {
  final Widget child;
  const _HorizontalScroll({required this.child});

  @override
  State<_HorizontalScroll> createState() => _HorizontalScrollState();
}

class _HorizontalScrollState extends State<_HorizontalScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}
