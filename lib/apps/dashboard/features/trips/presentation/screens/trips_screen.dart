import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../widgets/trip_creation_wizard.dart';
import '../widgets/trip_pricing_editor_dialog.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';

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
                  'الرحلات التشغيلية',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'مركز التحكم وإدارة وجدولة الرحلات اليومية، السائقين، المركبات، الحجوزات والمدفوعات.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _openCreateTripWizard(context, state),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء رحلة بالمعالج'),
          ),
        ],
      ),
    );
  }

  void _openCreateTripWizard(BuildContext context, TripsLoaded state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<TripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripCreationWizard(
            routes: state.routesList,
            vehicles: state.vehiclesList,
            drivers: state.driversList,
          ),
        ),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                labelText: 'بحث برقم الرحلة، السائق أو المركبة',
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              final selected = state.tab == tab;
              return selected
                  ? FilledButton(
                      onPressed: () => cubit.changeWorkspaceTab(tab),
                      child: Text(label),
                    )
                  : OutlinedButton(
                      onPressed: () => cubit.changeWorkspaceTab(tab),
                      child: Text(label),
                    );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.medium),
          switch (state.tab) {
            TripWorkspaceTab.overview => _OverviewTab(trip: trip),
            TripWorkspaceTab.passengers => _PassengersTab(trip: trip),
            TripWorkspaceTab.seats => _SeatsTab(trip: trip),
            TripWorkspaceTab.pricing => _PricingTab(trip: trip, state: state),
            TripWorkspaceTab.packages => _PackagesTab(trip: trip, state: state),
            TripWorkspaceTab.payments => _PaymentsTab(trip: trip),
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

// --- TAB 1: OVERVIEW TAB ---
class _OverviewTab extends StatelessWidget {
  final OperationTrip trip;

  const _OverviewTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final cards = [
              _InfoCard(
                title: 'تفاصيل السائق والجدولة',
                icon: Icons.person_outline_rounded,
                items: [
                  ('السائق', trip.driver),
                  ('تاريخ الرحلة', trip.date),
                  ('وقت الانطلاق', trip.departure),
                  ('وقت الوصول المتوقع', trip.arrival),
                ],
              ),
              _InfoCard(
                title: 'تفاصيل المركبة والسعة',
                icon: Icons.airport_shuttle_outlined,
                items: [
                  ('المركبة ولوحتها', trip.vehicle),
                  ('السعة الكلية', '${trip.capacity} مقعد'),
                  ('المقاعد المحجوزة', '${trip.bookedSeats} مقاعد'),
                  ('المقاعد المتاحة', '${trip.availableSeats} مقاعد'),
                ],
              ),
            ];
            if (compact) {
              return Column(children: cards);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: c))).toList(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الجدول الزمني لمحطات الوقوف والانتظار المتوقع:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.medium),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: trip.routePoints.map((point) {
                    final isLast = point == trip.routePoints.last;
                    return Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          padding: const EdgeInsets.all(AppSpacing.small),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(60),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                            border: Border.all(color: scheme.outline.withAlpha(60)),
                          ),
                          child: Column(
                            children: [
                              Text('${point.order}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              const SizedBox(height: 2),
                              Text(point.order == 1 ? 'مغادرة ${trip.departure}' : 'وصول متوقع', style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
                            child: Icon(Icons.arrow_back_rounded, color: scheme.onSurfaceVariant, size: 18),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> items;

  const _InfoCard({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.small),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  children: [
                    Text(it.$1, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    const Spacer(),
                    Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// --- TAB 2: PASSENGERS MANIFEST ---
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
      'إجراءات الحجز',
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
            if (trip.passengers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Text('لا يوجد ركاب مسجلين على هذه الرحلة حالياً', style: TextStyle(color: scheme.onSurfaceVariant)),
              )
            else
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
                      Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                              onPressed: () => _openPassengerDialog(context, trip, p),
                              child: const Text('تعديل'),
                            ),
                            TextButton(
                              onPressed: () => context
                                  .read<TripsCubit>()
                                  .cancelPassenger(trip, p),
                              child: const Text('إلغاء حجز'),
                            ),
                            TextButton(
                              onPressed: () => _openMoveDialog(context, trip, p),
                              child: const Text('نقل مقعد'),
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

// --- TAB 3: VISUAL SEAT MAP ---
class _SeatsTab extends StatelessWidget {
  final OperationTrip trip;

  const _SeatsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsCubit>();
    final scheme = Theme.of(context).colorScheme;

    // Mini bus visualization
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
        Text('مخطط توزيع مقاعد الأوتوبيس (انقر على مقعد لتغيير حالته):', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.medium),
        Container(
          width: 380,
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(20),
            border: Border.all(color: scheme.outline.withAlpha(40)),
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
          child: Column(
            children: [
              // Dashboard / Driver Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 65,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.outline.withAlpha(40),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    child: const Center(
                      child: Text('مقعد\nالسائق', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Icon(Icons.directions_car_outlined, size: 28),
                  const SizedBox(width: 65), // Corridor space
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              const Divider(),
              const SizedBox(height: AppSpacing.medium),
              // Grid for Seats
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trip.seats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpacing.small,
                  mainAxisSpacing: AppSpacing.small,
                  mainAxisExtent: 60,
                ),
                itemBuilder: (context, index) {
                  final seat = trip.seats[index];
                  return InkWell(
                    onTap: () => _openSeatStateDialog(context, trip, seat, cubit),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _seatColor(context, seat.state).withAlpha(35),
                        border: Border.all(color: _seatColor(context, seat.state), width: 1.5),
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            seat.state == TripSeatState.available
                                ? Icons.airline_seat_recline_normal
                                : Icons.airline_seat_flat_rounded,
                            size: 18,
                            color: _seatColor(context, seat.state),
                          ),
                          Text(
                            seat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _seatColor(context, seat.state),
                            ),
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

// --- TAB 4: PRICING CONFIGURATIONS ---
class _PricingTab extends StatelessWidget {
  final OperationTrip trip;
  final TripsLoaded state;

  const _PricingTab({required this.trip, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('تسعير شرائح المسار:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openPricingEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة تسعير شريحة'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        if (state.pricingLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.pricingError != null)
          Text(state.pricingError!, style: TextStyle(color: scheme.error))
        else if (state.selectedTripPricing.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Text('لا توجد تسعيرات مخصصة لهذه الرحلة بعد.', style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1.2),
                  5: FlexColumnWidth(1.2),
                  6: FlexColumnWidth(1.5),
                },
                border: TableBorder.all(color: scheme.outline.withAlpha(50)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withAlpha(90)),
                    children: const [
                      Padding(padding: EdgeInsets.all(10), child: Text('الشريحة (من ← إلى)', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('تذكرة فردية', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('باقة 5 أيام', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('باقة 10 أيام', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('اشتراك شهري', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('اشتراك 3 شهور', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  ...state.selectedTripPricing.map((pr) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${pr.fromPointName} ← ${pr.toPointName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(padding: const EdgeInsets.all(10), child: Text('${pr.oneTimePrice.toStringAsFixed(0)} ${pr.currency}')),
                        Padding(padding: const EdgeInsets.all(10), child: Text('${pr.fiveDaysPrice.toStringAsFixed(0)} ${pr.currency}')),
                        Padding(padding: const EdgeInsets.all(10), child: Text('${pr.tenDaysPrice.toStringAsFixed(0)} ${pr.currency}')),
                        Padding(padding: const EdgeInsets.all(10), child: Text('${pr.monthlyPrice.toStringAsFixed(0)} ${pr.currency}')),
                        Padding(padding: const EdgeInsets.all(10), child: Text('${pr.threeMonthsPrice.toStringAsFixed(0)} ${pr.currency}')),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          child: Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () => _openPricingEditor(context, pr),
                                child: const Text('تعديل'),
                              ),
                              TextButton(
                                onPressed: () => context.read<TripsCubit>().toggleTripPricing(pr),
                                child: Text(pr.isActive ? 'تعطيل' : 'تفعيل'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openPricingEditor(BuildContext context, [TripPricing? pricing]) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripPricingEditorDialog(trip: trip, pricing: pricing),
        ),
      ),
    );
  }
}

// --- TAB 5: PACKAGES TAB ---
class _PackagesTab extends StatelessWidget {
  final OperationTrip trip;
  final TripsLoaded state;

  const _PackagesTab({required this.trip, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الباقات والاشتراكات النشطة للشريحة:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.medium),
        if (state.selectedTripPricing.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Text('يرجى إضافة تسعير شريحة أولاً لتفعيل الباقات.', style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          ...state.selectedTripPricing.map((pr) {
            final configs = [
              (name: 'اشتراك أسبوع عمل كامل', days: 5, price: pr.fiveDaysPrice),
              (name: 'اشتراك أسبوعين خلال الشهر', days: 10, price: pr.tenDaysPrice),
              (name: 'اشتراك شهري كامل', days: 22, price: pr.monthlyPrice),
              (name: 'اشتراك 3 شهور مميز', days: 66, price: pr.threeMonthsPrice),
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
                        Icon(Icons.card_membership_rounded, color: scheme.primary),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          'الشريحة: ${pr.fromPointName} ← ${pr.toPointName}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text('(التذكرة الفردية: ${pr.oneTimePrice.toStringAsFixed(0)} ج.م)', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.0),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.2),
                      },
                      border: TableBorder.all(color: scheme.outline.withAlpha(40)),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withAlpha(50)),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('اسم الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('السعر الأساسي', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('سعر الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الخصم', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الوفر', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ...configs.map((conf) {
                          final base = pr.oneTimePrice * conf.days;
                          final disc = base > 0 ? ((base - conf.price) / base * 100) : 0.0;
                          final savings = base - conf.price;
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(conf.name)),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${base.toStringAsFixed(0)} ج.م')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${conf.price.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${disc.toStringAsFixed(0)}%')),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${savings.toStringAsFixed(0)} ج.م',
                                  style: TextStyle(color: savings > 0 ? scheme.primary : scheme.error, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// --- TAB 6: PAYMENT VERIFICATION MANIFEST ---
class _PaymentsTab extends StatefulWidget {
  final OperationTrip trip;

  const _PaymentsTab({required this.trip});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  late List<OperationBooking> _tripBookings;

  @override
  void initState() {
    super.initState();
    _tripBookings = _generateMockBookings(widget.trip.id, widget.trip.route);
  }

  List<OperationBooking> _generateMockBookings(String tripId, String route) {
    final now = DateTime.now();
    return [
      OperationBooking(
        id: 'BKG-$tripId-101',
        passengerName: 'هاني فريد',
        phone: '01098234721',
        route: route,
        tripTime: '07:00 صباحاً',
        date: '٨ يونيو ٢٠٢٦',
        seat: '4',
        paymentMethod: BookingPaymentMethod.instaPay,
        status: BookingStatus.paymentUploaded,
        priority: BookingPriority.normal,
        assignedTrip: tripId,
        createdAt: now.subtract(const Duration(minutes: 10)),
        customerProfile: const BookingCustomerProfile(
          name: 'هاني فريد',
          phone: '01098234721',
          email: 'h.farid@gmail.com',
          tripsCount: '١٢',
          accountStatus: 'نشط',
        ),
        tripDetails: BookingTripDetails(
          route: route,
          date: '٨ يونيو ٢٠٢٦',
          time: '07:00 صباحاً',
          vehicle: 'أ ب ج ٤٥٦',
          driver: 'محمد أحمد',
        ),
        paymentDetails: const BookingPaymentDetails(
          amount: '50',
          method: BookingPaymentMethod.instaPay,
          status: 'قيد المراجعة',
          reference: 'INSTA-882348',
          receiptReference: 'INSTA-882348',
        ),
        attachments: const ['receipt.jpg'],
        notes: const [],
        timeline: const [],
      ),
      OperationBooking(
        id: 'BKG-$tripId-102',
        passengerName: 'رنا سليمان',
        phone: '01123487212',
        route: route,
        tripTime: '07:00 صباحاً',
        date: '٨ يونيو ٢٠٢٦',
        seat: '8',
        paymentMethod: BookingPaymentMethod.vodafoneCash,
        status: BookingStatus.underReview,
        priority: BookingPriority.vip,
        assignedTrip: tripId,
        createdAt: now.subtract(const Duration(hours: 1)),
        customerProfile: const BookingCustomerProfile(
          name: 'رنا سليمان',
          phone: '01123487212',
          email: 'r.soliman@gmail.com',
          tripsCount: '٥',
          accountStatus: 'نشط',
        ),
        tripDetails: BookingTripDetails(
          route: route,
          date: '٨ يونيو ٢٠٢٦',
          time: '07:00 صباحاً',
          vehicle: 'أ ب ج ٤٥٦',
          driver: 'محمد أحمد',
        ),
        paymentDetails: const BookingPaymentDetails(
          amount: '50',
          method: BookingPaymentMethod.vodafoneCash,
          status: 'قيد المراجعة',
          reference: 'VF-Cash-7723',
          receiptReference: 'VF-Cash-7723',
        ),
        attachments: const ['receipt.jpg'],
        notes: const [],
        timeline: const [],
      ),
      OperationBooking(
        id: 'BKG-$tripId-103',
        passengerName: 'خالد مصطفى',
        phone: '01229988223',
        route: route,
        tripTime: '07:00 صباحاً',
        date: '٨ يونيو ٢٠٢٦',
        seat: '11',
        paymentMethod: BookingPaymentMethod.instaPay,
        status: BookingStatus.approved,
        priority: BookingPriority.urgent,
        assignedTrip: tripId,
        createdAt: now.subtract(const Duration(hours: 2)),
        customerProfile: const BookingCustomerProfile(
          name: 'خالد مصطفى',
          phone: '01229988223',
          email: 'k.mostafa@gmail.com',
          tripsCount: '٢٤',
          accountStatus: 'نشط',
        ),
        tripDetails: BookingTripDetails(
          route: route,
          date: '٨ يونيو ٢٠٢٦',
          time: '07:00 صباحاً',
          vehicle: 'أ ب ج ٤٥٦',
          driver: 'محمد أحمد',
        ),
        paymentDetails: const BookingPaymentDetails(
          amount: '40',
          method: BookingPaymentMethod.instaPay,
          status: 'مقبول',
          reference: 'INSTA-110023',
          receiptReference: 'INSTA-110023',
        ),
        attachments: const ['receipt.jpg'],
        notes: const [],
        timeline: const [],
      ),
    ];
  }

  void _updateStatus(String bookingId, BookingStatus newStatus) {
    setState(() {
      _tripBookings = _tripBookings.map((b) {
        if (b.id != bookingId) return b;
        return b.copyWith(status: newStatus);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مراجعة وتوثيق مدفوعات الركاب للرحلة:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.medium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1050,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.5),
                5: FlexColumnWidth(1.5),
                6: FlexColumnWidth(2.2),
              },
              border: TableBorder.all(color: scheme.outline.withAlpha(40)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withAlpha(70)),
                  children: const [
                    Padding(padding: EdgeInsets.all(10), child: Text('رقم الحجز', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('المقعد', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('حالة الحجز', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('مراجعة تشغيلية', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ..._tripBookings.map((b) {
                  final reqActions = b.status == BookingStatus.paymentUploaded || b.status == BookingStatus.underReview;
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: Text(b.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.all(10), child: Text(b.passengerName)),
                      Padding(padding: const EdgeInsets.all(10), child: Text(b.seat)),
                      Padding(padding: const EdgeInsets.all(10), child: Text('${b.paymentDetails.amount} ج.م')),
                      Padding(padding: const EdgeInsets.all(10), child: Text(b.paymentMethod.label)),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: StatusChip(label: b.status.label),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: reqActions
                            ? Wrap(
                                spacing: 4,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => _updateStatus(b.id, BookingStatus.approved),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: const Text('قبول'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _updateStatus(b.id, BookingStatus.rejected),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: const Text('رفض'),
                                  ),
                                  TextButton(
                                    onPressed: () => _updateStatus(b.id, BookingStatus.requestReupload),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: const Text('إعادة رفع'),
                                  ),
                                ],
                              )
                            : const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('تمت المراجعة والتوثيق', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- TAB 7: TRIP EVENTS HISTORY ---
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
