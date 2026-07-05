import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';

import '../../domain/entities/live_trip.dart';
import '../cubit/live_trips_cubit.dart';
import '../cubit/live_trips_state.dart';
import '../widgets/live_monitoring_panel.dart';
import '../widgets/live_trip_card.dart';

class LiveTripsScreen extends StatefulWidget {
  const LiveTripsScreen({super.key});

  @override
  State<LiveTripsScreen> createState() => _LiveTripsScreenState();
}

class _LiveTripsScreenState extends State<LiveTripsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LiveTripsCubit>().loadLiveTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocConsumer<LiveTripsCubit, LiveTripsState>(
        listenWhen: (previous, current) {
          return current is LiveTripsLoaded && current.actionMessage != null;
        },
        listener: (context, state) {
          if (state is LiveTripsLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
            context.read<LiveTripsCubit>().clearActionMessage();
          }
        },
        builder: (context, state) {
          return switch (state) {
            LiveTripsLoading() => const DashboardLoading(
              rows: 5,
              showHeader: true,
            ),
            LiveTripsError(:final message) => DashboardErrorState(
              message: message,
              onRetry: () => context.read<LiveTripsCubit>().loadLiveTrips(),
            ),
            LiveTripsLoaded() => _LoadedView(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final LiveTripsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveTripsCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        if (compact) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              _HeaderCard(state: state),
              const SizedBox(height: AppSpacing.medium),
              _TripsList(state: state, onTap: cubit.selectTrip, compact: true),
              const SizedBox(height: AppSpacing.medium),
              if (state.selectedTrip == null)
                const _NoSelectedTrip()
              else
                LiveMonitoringPanel(
                  trip: state.selectedTrip!,
                  actionLoading: state.actionLoading,
                ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              _HeaderCard(state: state),
              const SizedBox(height: AppSpacing.large),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 390,
                      child: _TripsList(
                        state: state,
                        onTap: cubit.selectTrip,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: state.selectedTrip == null
                          ? const _NoSelectedTrip()
                          : LiveMonitoringPanel(
                              trip: state.selectedTrip!,
                              actionLoading: state.actionLoading,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.state});

  final LiveTripsLoaded state;

  @override
  Widget build(BuildContext context) {
    return DashboardModuleHeader(
      icon: Icons.near_me_rounded,
      title: 'متابعة الرحلات',
      subtitle:
          'تابع الرحلات، المحطات، الركاب، السائقين والتنبيهات من مكان واحد.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.read<LiveTripsCubit>().loadLiveTrips(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
        ),
      ],
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          _MetricChip(
            label: 'رحلات نشطة',
            value: '${state.trips.length}',
            icon: Icons.directions_bus_rounded,
          ),
          _MetricChip(
            label: 'تنبيهات',
            value: '${state.unresolvedAlertsCount}',
            icon: Icons.notifications_active_outlined,
          ),
          _MetricChip(
            label: 'حرجة',
            value: '${state.urgentAlertsCount}',
            icon: Icons.warning_amber_rounded,
            danger: state.urgentAlertsCount > 0,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripsList extends StatefulWidget {
  const _TripsList({
    required this.state,
    required this.onTap,
    required this.compact,
  });

  final LiveTripsLoaded state;
  final ValueChanged<String> onTap;
  final bool compact;

  @override
  State<_TripsList> createState() => _TripsListState();
}

class _TripsListState extends State<_TripsList> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TripsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.searchQuery != widget.state.searchQuery) {
      if (_searchController.text != widget.state.searchQuery) {
        _searchController.text = widget.state.searchQuery;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveTripsCubit>();
    final filtered = widget.state.filteredTrips;

    Widget listWidget;
    if (widget.state.trips.isEmpty) {
      listWidget = const EmptyState(
        title: 'لا توجد رحلات مباشرة الآن',
        subtitle: 'عند بدء الرحلات ستظهر هنا.',
      );
    } else if (filtered.isEmpty) {
      listWidget = const EmptyState(
        title: 'لا توجد نتائج مطابقة',
        subtitle: 'جرب تغيير فلاتر البحث أو الكلمات المفتاحية.',
      );
    } else {
      if (widget.compact) {
        listWidget = Column(
          children: filtered.map((trip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: LiveTripCard(
                trip: trip,
                selected: trip.id == widget.state.selectedTripId,
                onTap: () => widget.onTap(trip.id),
              ),
            );
          }).toList(),
        );
      } else {
        listWidget = ListView.builder(
          padding: const EdgeInsets.only(top: AppSpacing.small),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final trip = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: LiveTripCard(
                trip: trip,
                selected: trip.id == widget.state.selectedTripId,
                onTap: () => widget.onTap(trip.id),
              ),
            );
          },
        );
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الرحلات النشطة',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (widget.state.filterHealth != null ||
                  widget.state.filterStatus != null ||
                  widget.state.searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    cubit.setFilters(
                      clearHealth: true,
                      clearStatus: true,
                      query: '',
                    );
                  },
                  child: const Text(
                    'إعادة تعيين',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              cubit.setFilters(query: val);
            },
            decoration: InputDecoration(
              hintText: 'ابحث برقم الرحلة، المسار، أو السائق...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        cubit.setFilters(query: '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<LiveTripHealth?>(
                  initialValue: widget.state.filterHealth,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    labelText: 'الحالة الصحية',
                    labelStyle: const TextStyle(fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('الكل', style: TextStyle(fontSize: 11)),
                    ),
                    ...LiveTripHealth.values.map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                          h.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    cubit.setFilters(health: val, clearHealth: val == null);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: DropdownButtonFormField<LiveTripStatus?>(
                  initialValue: widget.state.filterStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    labelText: 'حالة الرحلة',
                    labelStyle: const TextStyle(fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('الكل', style: TextStyle(fontSize: 11)),
                    ),
                    ...LiveTripStatus.values.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    cubit.setFilters(status: val, clearStatus: val == null);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (widget.compact) listWidget else Expanded(child: listWidget),
        ],
      ),
    );
  }
}

class _NoSelectedTrip extends StatelessWidget {
  const _NoSelectedTrip();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: EmptyState(
        title: 'اختر رحلة لمتابعتها',
        subtitle:
            'ستظهر هنا كل بيانات الرحلة، السائق، المحطات، الركاب والتنبيهات.',
      ),
    );
  }
}
