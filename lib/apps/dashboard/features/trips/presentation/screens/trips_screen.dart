import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/presentation/cubit/trip_passengers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../widgets/trip_creation_wizard.dart';
import '../widgets/trip_pricing_tab.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => dashboardDi<TripsListCubit>()..load()),
        BlocProvider(create: (_) => dashboardDi<TripDetailsCubit>()),
        BlocProvider(create: (_) => dashboardDi<TripSeatsCubit>()),
        BlocProvider(create: (_) => dashboardDi<TripPricingCubit>()),
        BlocProvider(create: (_) => dashboardDi<TripPassengersCubit>()),
      ],
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: _TripsView(),
      ),
    );
  }
}

class _TripsView extends StatelessWidget {
  const _TripsView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TripSeatsCubit, TripSeatsState>(
          listener: (context, state) {
            if (state is TripSeatsSuccess) {
              context.read<TripDetailsCubit>().updateTripLocally(state.trip);
              context.read<TripsListCubit>().updateTripInList(state.trip);
            }
          },
        ),
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
        builder: (context, state) {
          return switch (state) {
            TripsListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TripsListError(:final message) => _ErrorView(message: message),
            TripsListLoaded() => _LoadedTrips(state: state),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _LoadedTrips extends StatelessWidget {
  const _LoadedTrips({required this.state});

  final TripsListLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: Icons.route_rounded,
          title: 'إدارة الرحلات',
          subtitle: 'تابع حركة الرحلات، الإشغال، والطاقم من مساحة عمل واحدة.',
          actions: [
            FilledButton.icon(
              onPressed: () => _createTrip(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('رحلة جديدة'),
            ),
          ],
          child: _SummaryStrip(state: state),
        ),
        const SizedBox(height: AppSpacing.medium),
        _SimpleToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _TripsList(state: state),
      ],
    );
  }

  void _createTrip(BuildContext context) {
    final listCubit = context.read<TripsListCubit>();
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
    ).then((_) => listCubit.load());
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.state});

  final TripsListLoaded state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.small)) /
            columns;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _SummaryItem(
              width: width,
              icon: Icons.today_rounded,
              label: 'رحلات اليوم',
              value: state.todayTrips,
              selected: state.quickFilter == 'today',
              onTap: () => context.read<TripsListCubit>().filterQuick('today'),
            ),
            _SummaryItem(
              width: width,
              icon: Icons.directions_bus_filled_rounded,
              label: 'قيد التشغيل',
              value: state.runningTrips,
              selected: state.quickFilter == 'active',
              onTap: () => context.read<TripsListCubit>().filterQuick('active'),
            ),
            _SummaryItem(
              width: width,
              icon: Icons.upcoming_rounded,
              label: 'رحلات قادمة',
              value: state.upcomingTrips,
              selected: state.quickFilter == 'upcoming',
              onTap: () =>
                  context.read<TripsListCubit>().filterQuick('upcoming'),
            ),
            _SummaryItem(
              width: width,
              icon: Icons.task_alt_rounded,
              label: 'مكتملة',
              value: state.completedTrips,
              selected: state.quickFilter == 'completed',
              onTap: () =>
                  context.read<TripsListCubit>().filterQuick('completed'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withAlpha(120)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: selected ? scheme.primary : null,
                    fontWeight: FontWeight.w900,
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

class _SimpleToolbar extends StatelessWidget {
  const _SimpleToolbar({required this.state});

  final TripsListLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsListCubit>();
    const filters = [
      ('all', 'الكل'),
      ('today', 'اليوم'),
      ('active', 'قيد التشغيل'),
      ('upcoming', 'قادمة'),
      ('completed', 'مكتملة'),
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            onChanged: cubit.search,
            decoration: const InputDecoration(
              hintText: 'ابحث بالمسار، السائق، المركبة، أو رقم الرحلة',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters
                .map(
                  (item) => ChoiceChip(
                    avatar: state.quickFilter == item.$1
                        ? const Icon(Icons.check_rounded, size: 16)
                        : null,
                    label: Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    selected: state.quickFilter == item.$1,
                    showCheckmark: false,
                    onSelected: (_) => cubit.filterQuick(item.$1),
                  ),
                )
                .toList(),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 12), chips],
            );
          }
          return Row(
            children: [
              SizedBox(width: 380, child: search),
              const SizedBox(width: 16),
              Expanded(child: chips),
            ],
          );
        },
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  const _TripsList({required this.state});

  final TripsListLoaded state;

  @override
  Widget build(BuildContext context) {
    final trips = state.filteredTrips;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _listTitle(state.quickFilter),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${trips.length} رحلة',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('لا توجد رحلات مطابقة للبحث الحالي.')),
            )
          else
            ...trips.indexed.map(
              (entry) => Padding(
                padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 10),
                child: _TripRow(trip: entry.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = trip.capacity == 0
        ? 0.0
        : (trip.bookedSeats / trip.capacity).clamp(0.0, 1.0);
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(
                            context,
                            trip.status,
                          ).withAlpha(22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.route_rounded,
                          color: _statusColor(context, trip.status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.route,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_friendlyDate(trip.date)}، ${trip.departure}'
                              '${trip.arrival.isEmpty ? '' : ' - ${trip.arrival}'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: trip.status.label,
                        color: _statusColor(context, trip.status).withAlpha(28),
                        textColor: _statusColor(context, trip.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Fact(
                          icon: Icons.person_outline_rounded,
                          text: trip.driver,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Fact(
                          icon: Icons.directions_bus_outlined,
                          text: trip.vehicle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: occupancy,
                            minHeight: 7,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${trip.bookedSeats} من ${trip.capacity} مقعد',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('عرض التفاصيل'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'المزيد',
                    onSelected: (value) {
                      if (value == 'copy') _duplicate(context);
                      if (value == 'delete') _delete(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy_rounded),
                          title: Text('نسخ الرحلة'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('حذف الرحلة'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    final detailsCubit = context.read<TripDetailsCubit>()..showDetails(trip);
    showDialog<void>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: detailsCubit),
          BlocProvider.value(value: context.read<TripsListCubit>()),
          BlocProvider.value(value: context.read<TripSeatsCubit>()),
          BlocProvider.value(value: context.read<TripPassengersCubit>()),
          BlocProvider.value(value: context.read<TripPricingCubit>()),
        ],
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: _TripDetailsDialog(),
        ),
      ),
    ).then((_) => detailsCubit.closeDetails());
  }

  void _duplicate(BuildContext context) {
    final listCubit = context.read<TripsListCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<TripCreationCubit>()..loadWizardData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripCreationWizardDialog(prefillTrip: trip),
        ),
      ),
    ).then((_) => listCubit.load());
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الرحلة؟'),
        content: Text('سيتم حذف رحلة ${trip.route} نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TripsListCubit>().deleteTrip(trip.id);
    }
  }
}

class _TripDetailsDialog extends StatelessWidget {
  const _TripDetailsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 840),
        child: BlocBuilder<TripDetailsCubit, TripDetailsState>(
          builder: (context, state) {
            if (state is! TripDetailsLoaded) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              children: [
                _DetailsHeader(state: state),
                const Divider(height: 1),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return Column(
                          children: [
                            _TripWorkspaceNav(state: state, horizontal: true),
                            const Divider(height: 1),
                            Expanded(child: _TripWorkspaceBody(state: state)),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 214,
                            child: _TripWorkspaceNav(state: state),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: _TripWorkspaceBody(state: state)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.state});

  final TripDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final next = _nextStatus(trip.status);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor(context, trip.status).withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: _statusColor(context, trip.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trip.route,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: trip.status.label,
                          color: _statusColor(
                            context,
                            trip.status,
                          ).withAlpha(24),
                          textColor: _statusColor(context, trip.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_friendlyDate(trip.date)}، ${trip.departure}'
                      '  •  ${trip.driver}',
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
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (next != null)
                FilledButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _changeStatus(context, next),
                  icon: state.isSaving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_actionLabel(next)),
                ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    OperationTripStatus next,
  ) async {
    final updated = await context.read<TripDetailsCubit>().updateStatus(next);
    if (updated != null && context.mounted) {
      context.read<TripsListCubit>().updateTripInList(updated);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة الرحلة.')));
    }
  }
}

class _TripWorkspaceNav extends StatelessWidget {
  const _TripWorkspaceNav({required this.state, this.horizontal = false});

  final TripDetailsLoaded state;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final destinations = [
      (
        tab: TripWorkspaceTab.overview,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'نظرة عامة',
        count: null as int?,
      ),
      (
        tab: TripWorkspaceTab.passengers,
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        label: 'الركاب',
        count: trip.passengers.length,
      ),
      (
        tab: TripWorkspaceTab.seats,
        icon: Icons.event_seat_outlined,
        selectedIcon: Icons.event_seat_rounded,
        label: 'المقاعد',
        count: trip.seats.length,
      ),
      (
        tab: TripWorkspaceTab.pricing,
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
        label: 'الأسعار',
        count: null as int?,
      ),
      (
        tab: TripWorkspaceTab.history,
        icon: Icons.history_rounded,
        selectedIcon: Icons.history_rounded,
        label: 'سجل الرحلة',
        count: trip.events.length,
      ),
    ];
    final items = destinations
        .map(
          (item) => _WorkspaceNavItem(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: item.label,
            count: item.count,
            selected: state.tab == item.tab,
            horizontal: horizontal,
            onTap: () =>
                context.read<TripDetailsCubit>().changeWorkspaceTab(item.tab),
          ),
        )
        .toList();
    if (horizontal) {
      return SizedBox(
        height: 64,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: items,
        ),
      );
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Text(
              'تفاصيل الرحلة',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _WorkspaceNavItem extends StatelessWidget {
  const _WorkspaceNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.horizontal,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? count;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: horizontal ? 0 : 6,
        left: horizontal ? 6 : 0,
      ),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.surface.withAlpha(170)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _TripWorkspaceBody extends StatelessWidget {
  const _TripWorkspaceBody({required this.state});

  final TripDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    return switch (state.tab) {
      TripWorkspaceTab.overview => _OverviewTab(trip: state.trip),
      TripWorkspaceTab.passengers => _PassengersTab(trip: state.trip),
      TripWorkspaceTab.seats => _SeatsTab(trip: state.trip),
      TripWorkspaceTab.pricing => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: TripPricingTab(trip: state.trip),
      ),
      TripWorkspaceTab.history => _HistoryTab(trip: state.trip),
      TripWorkspaceTab.payments => _OverviewTab(trip: state.trip),
    };
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withAlpha(70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withAlpha(35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SchedulePoint(
                    label: 'المغادرة',
                    time: trip.departure,
                    place: trip.routePoints.isEmpty
                        ? trip.route
                        : trip.routePoints.first.name,
                    alignedEnd: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Text(
                        _friendlyDate(trip.date),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 76,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: scheme.primary,
                            ),
                            Expanded(child: Divider(color: scheme.primary)),
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _SchedulePoint(
                    label: 'الوصول',
                    time: trip.arrival.isEmpty ? '—' : trip.arrival,
                    place: trip.routePoints.isEmpty
                        ? trip.route
                        : trip.routePoints.last.name,
                    alignedEnd: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader(
            title: 'بيانات التشغيل',
            subtitle: 'الطاقم، المركبة، والسعة المتاحة',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoCard(
                icon: Icons.person_rounded,
                label: 'السائق',
                value: trip.driver,
              ),
              _InfoCard(
                icon: Icons.directions_bus_rounded,
                label: 'المركبة',
                value: trip.vehicle,
              ),
              _InfoCard(
                icon: Icons.event_seat_rounded,
                label: 'الإشغال',
                value: '${trip.bookedSeats} من ${trip.capacity}',
              ),
              _InfoCard(
                icon: Icons.payments_rounded,
                label: 'سعر التذكرة',
                value: '${trip.ticketPrice} ${trip.currency}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'محطات المسار',
            subtitle: '${trip.routePoints.length} نقاط توقف مرتبة',
          ),
          const SizedBox(height: 12),
          if (trip.routePoints.isEmpty)
            const _EmptyInline(message: 'لا توجد نقاط مسار مسجلة.')
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: trip.routePoints.indexed.map((entry) {
                  final point = entry.$2;
                  final isLast = entry.$1 == trip.routePoints.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isLast
                                  ? scheme.primary
                                  : scheme.primaryContainer,
                              foregroundColor: isLast
                                  ? scheme.onPrimary
                                  : scheme.onPrimaryContainer,
                              child: Text(
                                '${point.order}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 30,
                                color: scheme.outlineVariant,
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            point.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (entry.$1 == 0 || isLast)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 16),
                          child: Text(
                            entry.$1 == 0 ? 'نقطة الانطلاق' : 'الوجهة',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SchedulePoint extends StatelessWidget {
  const _SchedulePoint({
    required this.label,
    required this.time,
    required this.place,
    required this.alignedEnd,
  });

  final String label;
  final String time;
  final String place;
  final bool alignedEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignedEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          place,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengersTab extends StatelessWidget {
  const _PassengersTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.passengers.isEmpty) {
      return const _EmptyTab(
        icon: Icons.people_outline_rounded,
        title: 'لا يوجد ركاب حتى الآن',
        message: 'ستظهر الحجوزات المؤكدة هنا تلقائياً.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: _SectionHeader(
            title: 'قائمة الركاب',
            subtitle: '${trip.passengers.length} حجز مؤكد على الرحلة',
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: trip.passengers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final passenger = trip.passengers[index];
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      passenger.name.trim().isEmpty
                          ? '؟'
                          : passenger.name.trim().characters.first,
                    ),
                  ),
                  title: Text(
                    passenger.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${passenger.phone}\n'
                    '${passenger.pickup} ← ${passenger.dropoff}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text('مقعد ${passenger.seat}')),
                      IconButton(
                        tooltip: 'إلغاء الحجز',
                        onPressed: () => context
                            .read<TripPassengersCubit>()
                            .cancelBooking(trip.id, passenger.id),
                        icon: const Icon(Icons.person_remove_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SeatsTab extends StatelessWidget {
  const _SeatsTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.seats.isEmpty) {
      return const _EmptyTab(
        icon: Icons.event_seat_outlined,
        title: 'لا توجد خريطة مقاعد',
        message: 'لم يتم إنشاء مقاعد لهذه الرحلة بعد.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'خريطة المقاعد',
                subtitle:
                    '${trip.availableSeats} متاح • ${trip.bookedSeats} محجوز'
                    ' • ${trip.blockedSeats} محظور',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: TripSeatState.values
                    .map((state) => _SeatLegend(state: state))
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisExtent: 92,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: trip.seats.length,
            itemBuilder: (context, index) {
              final seat = trip.seats[index];
              return PopupMenuButton<TripSeatState>(
                tooltip: 'تغيير حالة المقعد',
                onSelected: (value) => context
                    .read<TripSeatsCubit>()
                    .changeSeatState(trip.id, seat.id, value),
                itemBuilder: (_) => TripSeatState.values
                    .map(
                      (value) =>
                          PopupMenuItem(value: value, child: Text(value.label)),
                    )
                    .toList(),
                child: Card(
                  elevation: 0,
                  color: _seatColor(context, seat.state),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_seat_rounded),
                      Text(
                        seat.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        seat.state.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.events.isEmpty) {
      return const _EmptyTab(
        icon: Icons.history_rounded,
        title: 'لا يوجد نشاط مسجل',
        message: 'ستظهر تغييرات حالة الرحلة والأحداث التشغيلية هنا.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: _SectionHeader(
            title: 'سجل الرحلة',
            subtitle: '${trip.events.length} أحداث مسجلة زمنياً',
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: trip.events.length,
            itemBuilder: (context, index) {
              final event = trip.events[index];
              return ListTile(
                leading: Icon(
                  event.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: event.done
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(event.description),
                trailing: Text(event.time),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.state});

  final TripSeatState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _seatColor(context, state),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(state.label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 17), const SizedBox(width: 5), Text(text)],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: context.read<TripsListCubit>().load,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

OperationTripStatus? _nextStatus(OperationTripStatus status) {
  return switch (status) {
    OperationTripStatus.scheduled => OperationTripStatus.openForBooking,
    OperationTripStatus.openForBooking => OperationTripStatus.boarding,
    OperationTripStatus.boarding => OperationTripStatus.inProgress,
    OperationTripStatus.inProgress => OperationTripStatus.completed,
    OperationTripStatus.completed || OperationTripStatus.cancelled => null,
  };
}

String _actionLabel(OperationTripStatus status) {
  return switch (status) {
    OperationTripStatus.openForBooking => 'فتح الحجز',
    OperationTripStatus.boarding => 'بدء صعود الركاب',
    OperationTripStatus.inProgress => 'بدء الرحلة',
    OperationTripStatus.completed => 'إنهاء الرحلة',
    _ => status.label,
  };
}

Color _statusColor(BuildContext context, OperationTripStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    OperationTripStatus.scheduled => scheme.secondary,
    OperationTripStatus.openForBooking => scheme.primary,
    OperationTripStatus.boarding => scheme.tertiary,
    OperationTripStatus.inProgress => Colors.green,
    OperationTripStatus.completed => Colors.teal,
    OperationTripStatus.cancelled => scheme.error,
  };
}

Color _seatColor(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.primaryContainer,
    TripSeatState.reserved => scheme.secondaryContainer,
    TripSeatState.paid => Colors.green.withAlpha(60),
    TripSeatState.subscription => scheme.tertiaryContainer,
    TripSeatState.blocked => scheme.errorContainer,
  };
}

String _listTitle(String filter) {
  return switch (filter) {
    'today' => 'رحلات اليوم',
    'active' => 'الرحلات قيد التشغيل',
    'upcoming' => 'الرحلات القادمة',
    'completed' => 'الرحلات المكتملة',
    _ => 'كل الرحلات',
  };
}

String _friendlyDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = day.difference(today).inDays;
  if (difference == 0) return 'اليوم';
  if (difference == 1) return 'غداً';
  if (difference == -1) return 'أمس';
  const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return '${weekdays[date.weekday - 1]}، ${date.day}/${date.month}';
}
