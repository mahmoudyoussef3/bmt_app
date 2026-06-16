import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/presentation/cubit/trip_passengers_cubit.dart';

import '../widgets/trip_pricing_tab.dart';
import '../widgets/trip_creation_wizard.dart';

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
                    _Header(listState: listState),
                    if (selectedTrip != null) ...[
                      const SizedBox(height: AppSpacing.large),
                      _TripWorkspace(trip: selectedTrip),
                    ],
                    const SizedBox(height: AppSpacing.large),
                    _DashboardKPIs(listState: listState),
                    const SizedBox(height: AppSpacing.large),
                    _FilterBar(listState: listState),
                    const SizedBox(height: AppSpacing.medium),
                    _TripsTable(listState: listState, onOpenTrip: _openTrip),
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
}

/// Header panel with page title and global actions.
class _Header extends StatelessWidget {
  final TripsListLoaded listState;
  const _Header({required this.listState});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة وجدولة الرحلات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'لوحة التحكم التشغيلية لجدولة مسارات الأوتوبيس، تعيين السائقين وإدارة الحجوزات والأسعار.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'إنشاء رحلة جديدة عبر معالج الخطوات',
            child: FilledButton.icon(
              onPressed: () => _openCreateTripWizard(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء رحلة بالمعالج'),
            ),
          ),
        ],
      ),
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
    ).then((_) {
      // Reload the trips list after the wizard completes
      tripsCubit.load();
    });
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
    final items = [
      ('الرحلات اليوم', listState.todayTrips, Icons.today_outlined),
      ('الرحلات القادمة', listState.upcomingTrips, Icons.schedule_rounded),
      ('الرحلات الجارية', listState.runningTrips, Icons.near_me_outlined),
      (
        'الرحلات المكتملة',
        listState.completedTrips,
        Icons.check_circle_outline,
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 900
              ? (constraints.maxWidth - AppSpacing.small * 3) / 4
              : constraints.maxWidth >= 560
              ? (constraints.maxWidth - AppSpacing.small) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: items.map((item) {
              final (label, value, icon) = item;
              return SizedBox(
                width: itemWidth,
                child: _InlineKpi(label: label, value: value, icon: icon),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _InlineKpi extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _InlineKpi({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
  const _TripsTable({required this.listState, required this.onOpenTrip});
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
                      mainAxisExtent: 224,
                    ),
                    itemBuilder: (context, index) {
                      final trip = listState.filteredTrips[index];
                      return _TripOperationCard(
                        trip: trip,
                        selected: selectedId == trip.id,
                        onOpen: () => onOpenTrip(trip),
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

  const _TripOperationCard({
    required this.trip,
    required this.selected,
    required this.onOpen,
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
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<TripDetailsCubit, TripDetailsState>(
      builder: (context, state) {
        if (state is! TripDetailsLoaded) {
          return const SizedBox.shrink();
        }
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkspaceOperationsHeader(
                trip: trip,
                onClose: cubit.closeDetails,
                onChangeStatus: (nextStatus) async {
                  final updated = await cubit.updateStatus(nextStatus);
                  if (updated != null && context.mounted) {
                    context.read<TripsListCubit>().updateTripInList(updated);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.small),
              const Divider(),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: TripWorkspaceTab.values.map((tab) {
                  final label = switch (tab) {
                    TripWorkspaceTab.overview => 'نظرة عامة',
                    TripWorkspaceTab.passengers => 'الركاب',
                    TripWorkspaceTab.seats => 'المقاعد',
                    TripWorkspaceTab.pricing => 'التسعير',
                    TripWorkspaceTab.packages => 'الباقات',
                    TripWorkspaceTab.payments => 'المدفوعات والتوثيق',
                    TripWorkspaceTab.history => 'السجل',
                  };
                  final icon = switch (tab) {
                    TripWorkspaceTab.overview => Icons.dashboard_outlined,
                    TripWorkspaceTab.passengers => Icons.people_outline_rounded,
                    TripWorkspaceTab.seats => Icons.event_seat_outlined,
                    TripWorkspaceTab.pricing => Icons.payments_outlined,
                    TripWorkspaceTab.packages => Icons.card_giftcard_outlined,
                    TripWorkspaceTab.payments => Icons.receipt_long_outlined,
                    TripWorkspaceTab.history => Icons.history_rounded,
                  };
                  final selected = state.tab == tab;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(label),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => cubit.changeWorkspaceTab(tab),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Content for each tab
              switch (state.tab) {
                TripWorkspaceTab.overview => _OverviewTab(trip: trip),
                TripWorkspaceTab.passengers => _PassengersTab(trip: trip),
                TripWorkspaceTab.seats => _SeatsTab(trip: trip),
                TripWorkspaceTab.pricing => TripPricingTab(trip: trip),
                TripWorkspaceTab.packages => _PackagesTab(trip: trip),
                TripWorkspaceTab.payments => _PaymentsTab(trip: trip),
                TripWorkspaceTab.history => _HistoryTab(trip: trip),
              },
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final OperationTrip trip;
  const _OverviewTab({required this.trip});
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
  const _PassengersTab({required this.trip});

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
            _ManifestEmptyState(color: scheme.onSurfaceVariant)
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

class _ManifestEmptyState extends StatelessWidget {
  final Color color;

  const _ManifestEmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Icon(Icons.people_outline_rounded, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'لا يوجد ركاب مسجلين على هذه الرحلة حالياً.',
              style: TextStyle(color: color),
            ),
          ),
        ],
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

class _SeatsTab extends StatelessWidget {
  final OperationTrip trip;
  const _SeatsTab({required this.trip});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = _occupancyRatio(trip);
    final columns = trip.seats.isEmpty
        ? 4
        : trip.seats.map((seat) => seat.column).reduce((a, b) => a > b ? a : b);
    final seatColumns = columns.clamp(3, 6);
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
                    'حالة المقاعد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _OccupancyBar(
                    ratio: occupancy,
                    label:
                        '${trip.bookedSeats}/${trip.capacity} مقعد مشغول - ${trip.availableSeats} متاح',
                  ),
                ],
              );
              final legend = Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: TripSeatState.values
                    .map(
                      (s) => StatusChip(
                        label: s.label,
                        color: _seatColor(context, s).withAlpha(35),
                        textColor: _seatColor(context, s),
                      ),
                    )
                    .toList(),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summary,
                    const SizedBox(height: AppSpacing.medium),
                    legend,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مخطط المقاعد القياسية',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'انقر على أي مقعد لتغيير حالته. كل المقاعد قياسية.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.medium),
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
                            itemCount: trip.seats.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: seatColumns,
                                  crossAxisSpacing: AppSpacing.small,
                                  mainAxisSpacing: AppSpacing.small,
                                  mainAxisExtent: 64,
                                ),
                            itemBuilder: (context, index) {
                              final seat = trip.seats[index];
                              return _SeatTile(
                                trip: trip,
                                seat: seat,
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

class _SeatTile extends StatelessWidget {
  final OperationTrip trip;
  final TripSeat seat;
  final TripSeatsCubit cubit;

  const _SeatTile({
    required this.trip,
    required this.seat,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _seatColor(context, seat.state);
    return Semantics(
      button: true,
      label: 'المقعد ${seat.label}، الحالة ${seat.state.label}',
      child: Tooltip(
        message: 'المقعد ${seat.label}: ${seat.state.label}',
        child: InkWell(
          onTap: () => _openSeatStateDialog(context, trip, seat, cubit),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
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
                      : Icons.event_seat_rounded,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Packages tab and payments/history tabs are reused from original
class _PackagesTab extends StatefulWidget {
  final OperationTrip trip;
  const _PackagesTab({required this.trip});
  @override
  State<_PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<_PackagesTab> {
  @override
  void initState() {
    super.initState();
    context.read<TripPricingCubit>().loadPricing(widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<TripPricingCubit, TripPricingState>(
      builder: (context, state) {
        if (state is TripPricingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TripPricingError) {
          return Text(state.message, style: TextStyle(color: scheme.error));
        }
        if (state is TripPricingLoaded) {
          if (state.pricing.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Text(
                'يرجى إضافة تسعير شريحة أولاً لتفعيل الباقات.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الباقات والاشتراكات النشطة للشريحة:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.medium),
              ...state.pricing.map((pr) {
                final configs = [
                  (
                    name: 'اشتراك أسبوع عمل كامل',
                    days: 5,
                    price: pr.fiveDaysPrice,
                  ),
                  (
                    name: 'اشتراك أسبوعين خلال الشهر',
                    days: 10,
                    price: pr.tenDaysPrice,
                  ),
                  (name: 'اشتراك شهري كامل', days: 22, price: pr.monthlyPrice),
                  (
                    name: 'اشتراك 3 شهور مميز',
                    days: 66,
                    price: pr.threeMonthsPrice,
                  ),
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.card_membership_rounded,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              'الشريحة: ${pr.fromPointName} ← ${pr.toPointName}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              '(التذكرة الفردية: ${pr.oneTimePrice.toStringAsFixed(0)} ج.م)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = constraints.maxWidth >= 900
                                ? (constraints.maxWidth -
                                          AppSpacing.small * 3) /
                                      4
                                : constraints.maxWidth >= 620
                                ? (constraints.maxWidth - AppSpacing.small) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.small,
                              children: configs.map((c) {
                                final basePrice = pr.oneTimePrice * c.days;
                                final discPercent = basePrice > 0
                                    ? ((basePrice - c.price) / basePrice * 100)
                                    : 0.0;
                                final savings = basePrice - c.price;
                                return SizedBox(
                                  width: tileWidth,
                                  child: _PackageTierTile(
                                    name: c.name,
                                    days: c.days,
                                    basePrice: basePrice,
                                    packagePrice: c.price,
                                    discountPercent: discPercent,
                                    savings: savings,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PackageTierTile extends StatelessWidget {
  final String name;
  final int days;
  final double basePrice;
  final double packagePrice;
  final double discountPercent;
  final double savings;

  const _PackageTierTile({
    required this.name,
    required this.days,
    required this.basePrice,
    required this.packagePrice,
    required this.discountPercent,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final savingsColor = savings > 0 ? scheme.primary : scheme.error;
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
              Icon(
                Icons.card_membership_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            '$days يوم',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          _MiniValueRow(
            label: 'السعر',
            value: '${packagePrice.toStringAsFixed(0)} ج.م',
          ),
          _MiniValueRow(
            label: 'قبل الخصم',
            value: '${basePrice.toStringAsFixed(0)} ج.م',
          ),
          _MiniValueRow(
            label: 'الخصم',
            value: '${discountPercent.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'وفر ${savings.toStringAsFixed(0)} ج.م',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: savingsColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final OperationTrip trip;
  const _PaymentsTab({required this.trip});
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Text(
                  'لا توجد حجوزات مرتبطة بهذه الرحلة حتى الآن.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
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
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                'لا توجد أحداث مسجلة لهذه الرحلة بعد.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withAlpha(35),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                        border: Border.all(color: scheme.outline.withAlpha(45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                event.time,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
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
  TripSeatsCubit cubit,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('المقعد ${seat.label}'),
        content: Wrap(
          spacing: AppSpacing.small,
          children: TripSeatState.values
              .map(
                (state) => FilledButton.tonal(
                  onPressed: () {
                    cubit.changeSeatState(trip.id, seat.id, state);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(state.label),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
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
