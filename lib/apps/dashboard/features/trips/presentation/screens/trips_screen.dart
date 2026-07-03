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
          subtitle: 'اختر رحلة، راجع بياناتها، ثم نفّذ الإجراء المطلوب.',
          actions: [
            FilledButton.icon(
              onPressed: () => _createTrip(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('رحلة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        _SummaryStrip(state: state),
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
        final width = constraints.maxWidth < 700
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryItem(
              width: width,
              icon: Icons.today_rounded,
              label: 'رحلات اليوم',
              value: state.todayTrips,
            ),
            _SummaryItem(
              width: width,
              icon: Icons.directions_bus_filled_rounded,
              label: 'قيد التشغيل',
              value: state.runningTrips,
            ),
            _SummaryItem(
              width: width,
              icon: Icons.upcoming_rounded,
              label: 'رحلات قادمة',
              value: state.upcomingTrips,
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
  });

  final double width;
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
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
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            onChanged: cubit.search,
            decoration: const InputDecoration(
              hintText: 'ابحث بالمسار أو السائق أو المركبة',
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
                    label: Text(item.$2),
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
              SizedBox(width: 340, child: search),
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
                'الرحلات',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text('${trips.length} رحلة'),
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
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          trip.route,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _Fact(
                        icon: Icons.schedule_rounded,
                        text: '${trip.date} • ${trip.departure}',
                      ),
                      _Fact(
                        icon: Icons.person_outline_rounded,
                        text: trip.driver,
                      ),
                      _Fact(
                        icon: Icons.directions_bus_outlined,
                        text: trip.vehicle,
                      ),
                      _Fact(
                        icon: Icons.event_seat_outlined,
                        text: '${trip.bookedSeats}/${trip.capacity} محجوز',
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
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('فتح'),
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
                    title,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
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
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 820),
        child: BlocBuilder<TripDetailsCubit, TripDetailsState>(
          builder: (context, state) {
            if (state is! TripDetailsLoaded) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  _DetailsHeader(state: state),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(icon: Icon(Icons.info_outline), text: 'الملخص'),
                      Tab(icon: Icon(Icons.people_outline), text: 'الركاب'),
                      Tab(
                        icon: Icon(Icons.event_seat_outlined),
                        text: 'المقاعد',
                      ),
                      Tab(icon: Icon(Icons.payments_outlined), text: 'الأسعار'),
                      Tab(icon: Icon(Icons.history_rounded), text: 'السجل'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(trip: state.trip),
                        _PassengersTab(trip: state.trip),
                        _SeatsTab(trip: state.trip),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: TripPricingTab(trip: state.trip),
                        ),
                        _HistoryTab(trip: state.trip),
                      ],
                    ),
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.route,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${trip.date} • ${trip.departure} • ${trip.driver}'),
              ],
            ),
          ),
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
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'محطات المسار',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...trip.routePoints.map(
            (point) => ListTile(
              leading: CircleAvatar(child: Text('${point.order}')),
              title: Text(point.name),
            ),
          ),
        ],
      ),
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
      return const Center(child: Text('لا يوجد ركاب في هذه الرحلة بعد.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: trip.passengers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final passenger = trip.passengers[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              passenger.name.trim().isEmpty
                  ? '؟'
                  : passenger.name.trim().characters.first,
            ),
          ),
          title: Text(passenger.name),
          subtitle: Text(
            '${passenger.phone} • ${passenger.pickup} ← ${passenger.dropoff}',
          ),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
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
        );
      },
    );
  }
}

class _SeatsTab extends StatelessWidget {
  const _SeatsTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.seats.isEmpty) {
      return const Center(child: Text('لم يتم إنشاء مقاعد لهذه الرحلة.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
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
          onSelected: (value) => context.read<TripSeatsCubit>().changeSeatState(
            trip.id,
            seat.id,
            value,
          ),
          itemBuilder: (_) => TripSeatState.values
              .map(
                (value) =>
                    PopupMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          child: Card(
            color: _seatColor(context, seat.state),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_seat_rounded),
                Text(
                  seat.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(seat.state.label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.events.isEmpty) {
      return const Center(child: Text('لا توجد أحداث مسجلة لهذه الرحلة.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: trip.events.length,
      itemBuilder: (context, index) {
        final event = trip.events[index];
        return ListTile(
          leading: Icon(
            event.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
          ),
          title: Text(event.title),
          subtitle: Text(event.description),
          trailing: Text(event.time),
        );
      },
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
