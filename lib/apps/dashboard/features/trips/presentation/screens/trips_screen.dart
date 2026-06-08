import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_trip.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsCubit, TripsState>(
      builder: (context, state) {
        return switch (state) {
          TripsLoading() => const Center(child: CircularProgressIndicator()),
          TripsError(:final message) => _TripsError(message: message),
          TripsLoaded() => _TripsOperationsView(state: state),
        };
      },
    );
  }
}

class _TripsOperationsView extends StatefulWidget {
  final TripsLoaded state;

  const _TripsOperationsView({required this.state});

  @override
  State<_TripsOperationsView> createState() => _TripsOperationsViewState();
}

class _TripsOperationsViewState extends State<_TripsOperationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _Header(state: state),
        if (state.selectedTrip != null) ...[
          const SizedBox(height: AppSpacing.large),
          _TripWorkspace(state: state, trip: state.selectedTrip!),
        ],
        const SizedBox(height: AppSpacing.large),
        _Kpis(state: state),
        const SizedBox(height: AppSpacing.large),
        _FilterBar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _TripsTable(state: state, onOpenTrip: _openTrip),
      ],
    );
  }

  void _openTrip(OperationTrip trip) {
    context.read<TripsCubit>().showDetails(trip);
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

class _Header extends StatelessWidget {
  final TripsLoaded state;

  const _Header({required this.state});

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
                  'الرحلات',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'مساحة تشغيل سريعة لفتح الرحلة وإدارة الركاب والمقاعد بدون مغادرة الشاشة.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _openCreateTripPanel(context, state),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء رحلة'),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  final TripsLoaded state;

  const _Kpis({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('الرحلات اليوم', state.todayTrips, Icons.today_outlined),
      ('الرحلات القادمة', state.upcomingTrips, Icons.schedule_rounded),
      ('الرحلات الجارية', state.runningTrips, Icons.near_me_outlined),
      ('الرحلات المكتملة', state.completedTrips, Icons.check_circle_outline),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            final (label, value, icon) = items[index];
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(child: Text(label)),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TripsLoaded state;

  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1050;
          final search = SizedBox(
            width: compact ? constraints.maxWidth : 280,
            child: TextField(
              onChanged: cubit.search,
              decoration: const InputDecoration(
                labelText: 'بحث',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          );
          final filters = [
            SizedBox(width: 180, child: _StatusFilter(state: state)),
            SizedBox(
              width: 220,
              child: _StringFilter(
                label: 'المسار',
                value: state.routeFilter,
                values: state.routes,
                onChanged: cubit.filterRoute,
              ),
            ),
            SizedBox(
              width: 190,
              child: _StringFilter(
                label: 'السائق',
                value: state.driverFilter,
                values: state.drivers,
                onChanged: cubit.filterDriver,
              ),
            ),
            SizedBox(
              width: 180,
              child: _StringFilter(
                label: 'التاريخ',
                value: state.dateFilter,
                values: state.dates,
                onChanged: cubit.filterDate,
              ),
            ),
          ];
          return Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [search, ...filters],
          );
        },
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final TripsLoaded state;

  const _StatusFilter({required this.state});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<OperationTripStatus?>(
      initialValue: state.statusFilter,
      decoration: const InputDecoration(labelText: 'الحالة'),
      items: [
        const DropdownMenuItem(value: null, child: Text('الكل')),
        ...OperationTripStatus.values.map(
          (status) =>
              DropdownMenuItem(value: status, child: Text(status.label)),
        ),
      ],
      onChanged: context.read<TripsCubit>().filterStatus,
    );
  }
}

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
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (next) => onChanged(next ?? 'الكل'),
    );
  }
}

class _TripsTable extends StatelessWidget {
  final TripsLoaded state;
  final ValueChanged<OperationTrip> onOpenTrip;

  const _TripsTable({required this.state, required this.onOpenTrip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headers = const [
      'رقم الرحلة',
      'المسار',
      'وقت الانطلاق',
      'السائق',
      'المركبة',
      'المقاعد المحجوزة',
      'المقاعد المتاحة',
      'الحالة',
      'إجراء',
    ];
    final headerCells = headers
        .map(
          (h) => Expanded(
            child: Text(h, style: Theme.of(context).textTheme.labelLarge),
          ),
        )
        .toList();
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${state.filteredTrips.length} رحلة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1280,
              child: Column(
                children: [
                  Container(
                    color: scheme.surfaceContainerHighest.withAlpha(90),
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Row(children: headerCells),
                  ),
                  if (state.filteredTrips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      child: Text(
                        'لا توجد رحلات مطابقة للفلاتر الحالية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...state.filteredTrips.map((trip) {
                      final selected = state.selectedTrip?.id == trip.id;
                      return InkWell(
                        onTap: () => onOpenTrip(trip),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.small),
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primary.withAlpha(18)
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                color: scheme.outline.withAlpha(90),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (selected) ...[
                                      Icon(
                                        Icons.visibility_rounded,
                                        size: 18,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.xSmall),
                                    ],
                                    Text(trip.id),
                                  ],
                                ),
                              ),
                              Expanded(child: Text(trip.route)),
                              Expanded(
                                child: Text('${trip.date} - ${trip.departure}'),
                              ),
                              Expanded(child: Text(trip.driver)),
                              Expanded(child: Text(trip.vehicle)),
                              Expanded(child: Text('${trip.bookedSeats}')),
                              Expanded(child: Text('${trip.availableSeats}')),
                              Expanded(
                                child: StatusChip(label: trip.status.label),
                              ),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => onOpenTrip(trip),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('فتح'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripWorkspace extends StatelessWidget {
  final TripsLoaded state;
  final OperationTrip trip;

  const _TripWorkspace({required this.state, required this.trip});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsCubit>();
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مساحة تشغيل ${trip.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      '${trip.route} • ${trip.departure} • ${trip.driver} • ${trip.vehicle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _WorkspaceFact(label: 'محجوز', value: '${trip.bookedSeats}'),
              const SizedBox(width: AppSpacing.small),
              _WorkspaceFact(label: 'متاح', value: '${trip.availableSeats}'),
              const SizedBox(width: AppSpacing.small),
              StatusChip(label: trip.status.label),
              const SizedBox(width: AppSpacing.small),
              TextButton.icon(
                onPressed: cubit.closeDetails,
                icon: const Icon(Icons.close_rounded),
                label: const Text('إغلاق'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: TripWorkspaceTab.values.map((tab) {
              final label = switch (tab) {
                TripWorkspaceTab.info => 'معلومات الرحلة',
                TripWorkspaceTab.passengers => 'الركاب',
                TripWorkspaceTab.seats => 'المقاعد',
                TripWorkspaceTab.history => 'السجل',
              };
              final selected = state.tab == tab;
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.small,
                ),
                child: selected
                    ? FilledButton(
                        onPressed: () => cubit.changeWorkspaceTab(tab),
                        child: Text(label),
                      )
                    : OutlinedButton(
                        onPressed: () => cubit.changeWorkspaceTab(tab),
                        child: Text(label),
                      ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.medium),
          switch (state.tab) {
            TripWorkspaceTab.info => _InfoTab(trip: trip),
            TripWorkspaceTab.passengers => _PassengersTab(trip: trip),
            TripWorkspaceTab.seats => _SeatsTab(trip: trip),
            TripWorkspaceTab.history => _HistoryTab(trip: trip),
          },
        ],
      ),
    );
  }
}

class _WorkspaceFact extends StatelessWidget {
  final String label;
  final String value;

  const _WorkspaceFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _InfoTab extends StatefulWidget {
  final OperationTrip trip;

  const _InfoTab({required this.trip});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  late final TextEditingController route = TextEditingController(
    text: widget.trip.route,
  );
  late final TextEditingController driver = TextEditingController(
    text: widget.trip.driver,
  );
  late final TextEditingController vehicle = TextEditingController(
    text: widget.trip.vehicle,
  );
  late final TextEditingController departure = TextEditingController(
    text: widget.trip.departure,
  );
  late final TextEditingController arrival = TextEditingController(
    text: widget.trip.arrival,
  );
  late OperationTripStatus status = widget.trip.status;

  @override
  void dispose() {
    route.dispose();
    driver.dispose();
    vehicle.dispose();
    departure.dispose();
    arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoGrid(
          children: [
            TextField(
              controller: route,
              decoration: const InputDecoration(labelText: 'المسار'),
            ),
            TextField(
              controller: driver,
              decoration: const InputDecoration(labelText: 'السائق'),
            ),
            TextField(
              controller: vehicle,
              decoration: const InputDecoration(labelText: 'المركبة'),
            ),
            TextField(
              controller: departure,
              decoration: const InputDecoration(labelText: 'وقت الانطلاق'),
            ),
            TextField(
              controller: arrival,
              decoration: const InputDecoration(labelText: 'وقت الوصول'),
            ),
            DropdownButtonFormField<OperationTripStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: OperationTripStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (next) => setState(() => status = next ?? status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'السعة: ${trip.capacity} | المحجوز: ${trip.bookedSeats} | المتاح: ${trip.availableSeats}',
        ),
        const SizedBox(height: AppSpacing.small),
        Text('محطات المسار: ${trip.routeStops.join(' ← ')}'),
        const SizedBox(height: AppSpacing.medium),
        FilledButton(
          onPressed: () => context.read<TripsCubit>().updateTripInfo(
            trip.copyWith(
              route: route.text,
              driver: driver.text,
              vehicle: vehicle.text,
              departure: departure.text,
              arrival: arrival.text,
              status: status,
            ),
          ),
          child: const Text('حفظ التعديل'),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<Widget> children;

  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _PassengersTab extends StatelessWidget {
  final OperationTrip trip;

  const _PassengersTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headers = const [
      'الاسم',
      'الهاتف',
      'المقعد',
      'نقطة الصعود',
      'نقطة النزول',
      'طريقة الدفع',
      'الحالة',
      'إجراءات',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1120,
        child: Column(
          children: [
            Container(
              color: scheme.surfaceContainerHighest.withAlpha(90),
              padding: const EdgeInsets.all(AppSpacing.small),
              child: Row(
                children: headers
                    .map(
                      (h) => Expanded(
                        child: Text(
                          h,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            ...trip.passengers.map(
              (p) => Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: scheme.outline.withAlpha(90)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    Expanded(child: Text(p.phone)),
                    Expanded(child: Text(p.seat)),
                    Expanded(child: Text(p.pickup)),
                    Expanded(child: Text(p.dropoff)),
                    Expanded(child: Text(p.paymentMethod)),
                    Expanded(child: Text(p.status)),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xSmall,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _openPassengerDialog(context, trip, p),
                            child: const Text('تعديل'),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<TripsCubit>()
                                .cancelPassenger(trip, p),
                            child: const Text('إلغاء الحجز'),
                          ),
                          TextButton(
                            onPressed: () => _openMoveDialog(context, trip, p),
                            child: const Text('نقل لمقعد آخر'),
                          ),
                          TextButton(
                            onPressed: () => _openMessageDialog(context, p),
                            child: const Text('إرسال رسالة'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final cubit = context.read<TripsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.medium,
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
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          width: 420,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trip.seats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.small,
              mainAxisSpacing: AppSpacing.small,
              mainAxisExtent: 62,
            ),
            itemBuilder: (context, index) {
              final seat = trip.seats[index];
              return InkWell(
                onTap: () => _openSeatStateDialog(context, trip, seat, cubit),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _seatColor(context, seat.state).withAlpha(35),
                    border: Border.all(color: _seatColor(context, seat.state)),
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                  ),
                  child: Center(
                    child: Text(
                      '${seat.label}\n${seat.state.label}',
                      textAlign: TextAlign.center,
                    ),
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
  final OperationTrip trip;

  const _HistoryTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: trip.events
          .map(
            (event) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  event.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text('${event.time} - ${event.description}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _TripsError extends StatelessWidget {
  final String message;

  const _TripsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
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

void _openCreateTripPanel(BuildContext context, TripsLoaded state) {
  final routes = state.routes.where((route) => route != 'الكل').toList();
  final drivers = state.drivers.where((driver) => driver != 'الكل').toList();
  final vehicles = state.trips.map((trip) => trip.vehicle).toSet().toList();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<TripsCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _CreateTripPanel(
          routes: routes,
          drivers: drivers,
          vehicles: vehicles,
        ),
      ),
    ),
  );
}

class _CreateTripPanel extends StatefulWidget {
  final List<String> routes;
  final List<String> drivers;
  final List<String> vehicles;

  const _CreateTripPanel({
    required this.routes,
    required this.drivers,
    required this.vehicles,
  });

  @override
  State<_CreateTripPanel> createState() => _CreateTripPanelState();
}

class _CreateTripPanelState extends State<_CreateTripPanel> {
  late String route = widget.routes.first;
  late String driver = widget.drivers.first;
  late String vehicle = widget.vehicles.first;
  final date = TextEditingController(text: '٨ يونيو ٢٠٢٦');
  final departure = TextEditingController(text: '٩:٠٠');
  final capacity = TextEditingController(text: '14');
  String error = '';

  @override
  void dispose() {
    date.dispose();
    departure.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إنشاء رحلة', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<String>(
            initialValue: route,
            decoration: const InputDecoration(labelText: 'المسار'),
            items: widget.routes
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => route = v ?? route),
          ),
          const SizedBox(height: AppSpacing.small),
          DropdownButtonFormField<String>(
            initialValue: driver,
            decoration: const InputDecoration(labelText: 'السائق'),
            items: widget.drivers
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => driver = v ?? driver),
          ),
          const SizedBox(height: AppSpacing.small),
          DropdownButtonFormField<String>(
            initialValue: vehicle,
            decoration: const InputDecoration(labelText: 'المركبة'),
            items: widget.vehicles
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => vehicle = v ?? vehicle),
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: date,
                  decoration: const InputDecoration(labelText: 'تاريخ الرحلة'),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: TextField(
                  controller: departure,
                  decoration: const InputDecoration(labelText: 'وقت الانطلاق'),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: TextField(
                  controller: capacity,
                  decoration: const InputDecoration(labelText: 'السعة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text('محطات المسار يتم تحميلها تلقائياً ولا يعاد إنشاؤها هنا.'),
          if (error.isNotEmpty)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton(onPressed: _save, child: const Text('إنشاء الرحلة')),
        ],
      ),
    );
  }

  void _save() {
    final cap = int.tryParse(capacity.text.trim());
    if (route.isEmpty ||
        driver.isEmpty ||
        vehicle.isEmpty ||
        cap == null ||
        cap <= 0) {
      setState(() => error = 'المسار والسائق والمركبة والسعة مطلوبة');
      return;
    }
    context.read<TripsCubit>().createTrip(
      CreateTripInput(
        route: route,
        driver: driver,
        vehicle: vehicle,
        date: date.text,
        departure: departure.text,
        capacity: cap,
      ),
    );
    Navigator.of(context).pop();
  }
}

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
          width: 480,
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
              context.read<TripsCubit>().updatePassenger(
                trip,
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
              if (error.isNotEmpty)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await context.read<TripsCubit>().movePassenger(
                  trip,
                  passenger,
                  selected,
                );
                if (result != null) {
                  setState(() => error = result);
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

void _openMessageDialog(BuildContext context, TripPassenger passenger) {
  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إرسال رسالة'),
        content: Text(
          'تم تجهيز رسالة تشغيل إلى ${passenger.name} على ${passenger.phone} ببيانات الرحلة والمقعد.',
        ),
        actions: [
          FilledButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('تم'),
          ),
        ],
      ),
    ),
  );
}

void _openSeatStateDialog(
  BuildContext context,
  OperationTrip trip,
  TripSeat seat,
  TripsCubit cubit,
) {
  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('المقعد ${seat.label}'),
        content: Wrap(
          spacing: AppSpacing.small,
          children: TripSeatState.values
              .map(
                (state) => FilledButton.tonal(
                  onPressed: () {
                    cubit.updateSeatState(trip, seat, state);
                    Navigator.of(context).pop();
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
