import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/presentation/cubit/trip_passengers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../widgets/trips_analytics.dart';
import '../widgets/trip_cancellation_dialog.dart';
import '../widgets/trip_creation_wizard.dart';
import '../widgets/trip_pricing_tab.dart';
import '../widgets/trip_row_card.dart';
import '../widgets/trip_seat_map.dart';
import '../widgets/trip_ui_helpers.dart';
import '../widgets/trips_filter_sheet.dart';
import '../widgets/trips_grouped_view.dart';
import '../widgets/trips_timeline_view.dart';
import '../widgets/trips_view_mode_switch.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({
    super.key,
    this.onOpenModule,
    this.openPlannerOnStart = false,
  });

  /// Switches the shell to another module. Used by the trip planner to send an
  /// operator to Fleet when the driver they picked has no vehicle assigned — the fix
  /// is one screen away and the planner cannot make it from here. Same prop-drilled
  /// shape the home screen's module cards use.
  final ValueChanged<String>? onOpenModule;

  /// Open the trip planner immediately instead of waiting for the operator to
  /// find "رحلة جديدة". Set by the home screen's primary action, so "create a
  /// trip" from the landing page is one click rather than navigate-then-hunt.
  /// Honoured once per mount — see [_TripsViewState._plannerOpened].
  final bool openPlannerOnStart;

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
      child: _TripsView(
        onOpenModule: onOpenModule,
        openPlannerOnStart: openPlannerOnStart,
      ),
    );
  }
}

class _TripsView extends StatefulWidget {
  const _TripsView({this.onOpenModule, this.openPlannerOnStart = false});

  final ValueChanged<String>? onOpenModule;
  final bool openPlannerOnStart;

  @override
  State<_TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<_TripsView> {
  /// Guards the one-shot: the flag stays `true` on the widget for as long as
  /// the shell keeps Trips open, so without this the planner would reopen on
  /// every rebuild of the screen behind it.
  bool _plannerOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.openPlannerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _plannerOpened) return;
        _plannerOpened = true;
        openTripCreationWizard(context, onOpenModule: widget.onOpenModule);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onOpenModule = widget.onOpenModule;
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
            TripsListLoading() => const DashboardLoading(),
            TripsListError(:final message) => DashboardErrorState(
              message: message,
              onRetry: () => context.read<TripsListCubit>().load(),
            ),
            TripsListLoaded() => _LoadedTrips(
              state: state,
              onOpenModule: onOpenModule,
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _LoadedTrips extends StatelessWidget {
  const _LoadedTrips({required this.state, this.onOpenModule});

  final TripsListLoaded state;
  final ValueChanged<String>? onOpenModule;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.tripsActive,
          title: 'إدارة الرحلات',
          subtitle: 'تابع حركة الرحلات، الإشغال، والطاقم من مساحة عمل واحدة.',
          actions: [
            if (state.capReached)
              const DashboardCapNotice(
                rowCap: DashboardQueryCaps.trips,
                noun: 'رحلة',
                hint: 'ضيّق الفلاتر للوصول لرحلات أقدم.',
              ),
            FilledButton.icon(
              onPressed: () => _createTrip(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('رحلة جديدة'),
            ),
          ],
          sectionId: DashboardSectionIds.tripsHeader,
          // Folded, the counts still show — a trip that has passed its
          // departure time is the one thing on this screen nobody may miss
          // because a panel happened to be closed.
          collapsedSummary: DashboardSectionSummary(
            items: [
              // The warning leads the row, where a right-to-left reader starts.
              if (state.staleTrips > 0) 'فات موعدها ${state.staleTrips}',
              'اليوم ${state.todayTrips}',
              'قيد التشغيل ${state.runningTrips}',
              'قادمة ${state.upcomingTrips}',
              'مكتملة ${state.completedTrips}',
            ],
          ),
          summary: _SummaryStrip(state: state),
        ),
        const SizedBox(height: AppSpacing.medium),

        TripsAnalytics(state: state),
        const SizedBox(height: AppSpacing.medium),
        _SimpleToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        switch (state.viewMode) {
          TripsViewMode.list => _TripsList(state: state),
          TripsViewMode.grouped => TripsGroupedView(
            state: state,
            onOpenDetails: (trip) => _openTripDetails(context, trip),
          ),
          TripsViewMode.timeline => TripsTimelineView(
            trips: state.timelineTrips,
            onOpenDetails: (trip) => _openTripDetails(context, trip),
          ),
        },
      ],
    );
  }

  void _createTrip(BuildContext context) =>
      openTripCreationWizard(context, onOpenModule: onOpenModule);
}

/// Opens the trip planner over whatever is on screen and refreshes the list
/// when it closes.
///
/// Library-level rather than a method on the screen because two callers need
/// it: the header's "رحلة جديدة" button, and the shell handing off the home
/// screen's primary action. [context] must sit below the trips providers.
void openTripCreationWizard(
  BuildContext context, {
  ValueChanged<String>? onOpenModule,
}) {
  final listCubit = context.read<TripsListCubit>();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => dashboardDi<TripCreationCubit>()..loadWizardData(),
      child: TripCreationWizardDialog(onOpenModule: onOpenModule),
    ),
  ).then((_) => listCubit.load());
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
            if (state.staleTrips > 0)
              _SummaryItem(
                width: width,
                icon: Icons.report_problem_rounded,
                label: 'فات موعدها',
                value: state.staleTrips,
                selected: state.quickFilter == 'stale',
                alert: true,
                onTap: () =>
                    context.read<TripsListCubit>().filterQuick('stale'),
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
    this.alert = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  /// Renders the tile as an operational warning rather than a neutral stat.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = alert ? scheme.error : scheme.primary;
    return SizedBox(
      width: width,
      child: Material(
        color: selected
            ? accent.withAlpha(30)
            : alert
            ? scheme.errorContainer.withAlpha(60)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: selected || alert ? accent : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected || alert ? accent : scheme.onSurfaceVariant,
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
                    color: selected || alert ? accent : null,
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

  /// What the collapsed toolbar reports: the search term, the active quick
  /// chip, how many advanced filters are on, and the resulting row count.
  List<String> _summaryItems() {
    final items = <String>[];

    final query = state.searchQuery.trim();
    if (query.isNotEmpty) items.add('بحث: $query');

    const quickLabels = {
      'today': 'اليوم',
      'active': 'قيد التشغيل',
      'upcoming': 'قادمة',
      'completed': 'مكتملة',
      'stale': 'فات موعدها',
    };
    final quick = quickLabels[state.quickFilter];
    if (quick != null) items.add(quick);

    final advanced = [
      state.statusFilter != null,
      state.routeFilter != 'الكل',
      state.driverFilter != 'الكل',
      state.vehicleFilter != 'الكل',
      state.occupancyFilter != 'الكل',
      state.dateFilter != 'الكل',
    ].where((active) => active).length;
    if (advanced > 0) items.add('$advanced فلتر متقدم');

    if (items.isEmpty) return const ['بدون تصفية'];
    items.add('${state.filteredTrips.length} رحلة ظاهرة');
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsListCubit>();
    final filters = [
      ('all', 'الكل'),
      ('today', 'اليوم'),
      ('active', 'قيد التشغيل'),
      ('upcoming', 'قادمة'),
      ('completed', 'مكتملة'),
      if (state.staleTrips > 0) ('stale', 'فات موعدها'),
    ];
    return DashboardCollapsibleSection(
      sectionId: DashboardSectionIds.tripsFilters,
      icon: Icons.tune_rounded,
      title: 'البحث والتصفية',

      collapsedSummary: DashboardSectionSummary(items: _summaryItems()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = DebouncedSearchField(
            hintText: 'ابحث بالمسار، السائق، المركبة، أو رقم الرحلة',
            onChanged: cubit.search,
          );
          final filterButton = Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.outlined(
                tooltip: 'فلاتر متقدمة',
                onPressed: () => showTripsFilterSheet(context),
                icon: const Icon(Icons.tune_rounded),
              ),
              if (state.hasAdvancedFilters)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
          final viewModeRow = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TripsViewModeSwitch(
              viewMode: state.viewMode,
              onChanged: cubit.changeViewMode,
            ),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 8),
                    filterButton,
                  ],
                ),
                const SizedBox(height: 12),
                chips,
                const SizedBox(height: 12),
                viewModeRow,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: 380, child: search),
                  const SizedBox(width: 8),
                  filterButton,
                  const SizedBox(width: 16),
                  Expanded(child: chips),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: viewModeRow,
              ),
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
                child: TripRowCard(
                  trip: entry.$2,
                  onOpenDetails: () => _openTripDetails(context, entry.$2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _openTripDetails(BuildContext context, OperationTrip trip) {
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
      child: _TripDetailsDialog(),
    ),
  ).then((_) => detailsCubit.closeDetails());
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
    final isStale = trip.isStaleBooking();

    final next = isStale ? null : TripLifecycle.nextStep(trip.status);

    final publishBlocker = next == OperationTripStatus.openForBooking
        ? TripPublishBlocker.evaluate(trip)
        : null;
    final canCancel = !TripLifecycle.isTerminal(trip.status);
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
                  color: tripStatusColor(context, trip.status).withAlpha(22),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: tripStatusColor(context, trip.status),
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
                          color: tripStatusColor(
                            context,
                            trip.status,
                          ).withAlpha(24),
                          textColor: tripStatusColor(context, trip.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tripFriendlyDate(trip.date)}، ${trip.departure}'
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
                Tooltip(
                  message: publishBlocker?.message ?? '',
                  child: FilledButton.icon(
                    onPressed: state.isSaving || publishBlocker != null
                        ? null
                        : () => _changeStatus(context, next),
                    icon: state.isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            publishBlocker != null
                                ? Icons.lock_outline_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    label: Text(_actionLabel(next)),
                  ),
                ),
              if (canCancel && !isStale) ...[
                const SizedBox(width: 8),

                OutlinedButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _cancelTrip(context, trip),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('إلغاء الرحلة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );
          final header = constraints.maxWidth < 720
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: actions,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
          if (!isStale) return header;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              StaleTripBanner(
                actions: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (trip.status == OperationTripStatus.openForBooking)
                      FilledButton.tonalIcon(
                        onPressed: state.isSaving
                            ? null
                            : () => _closeStale(
                                context,
                                StaleTripOutcome.operated,
                              ),
                        icon: const Icon(Icons.task_alt_rounded, size: 18),
                        label: const Text('نُفّذت بالفعل — إنهاؤها'),
                      ),
                    TextButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () => _cancelTrip(context, trip),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('لم تُنفَّذ — إلغاؤها'),
                    ),
                  ],
                ),
              ),
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
    await _run(context, 'تعذر تحديث حالة الرحلة.', (cubit) {
      return cubit.updateStatus(next);
    });
  }

  Future<void> _cancelTrip(BuildContext context, OperationTrip trip) async {
    final reason = await showTripCancellationDialog(
      context,
      trip: trip,
      reasonRequired: TripLifecycle.cancellationNeedsReason(trip.status),
    );
    if (reason == null || !context.mounted) return;
    await _run(context, 'تعذر إلغاء الرحلة.', (cubit) {
      return cubit.cancelTrip(reason);
    });
  }

  Future<void> _closeStale(
    BuildContext context,
    StaleTripOutcome outcome,
  ) async {
    await _run(context, 'تعذر إغلاق الرحلة.', (cubit) {
      return cubit.closeStaleTrip(outcome);
    });
  }

  /// Runs a lifecycle action, keeps the list in step on success, and shows the
  /// *server's* reason on failure.
  ///
  /// Every lifecycle refusal is specific — no pricing configured, a reason missing,
  /// the transition not being an edge of the machine — and all of it used to be
  /// discarded in favour of one fixed sentence, which turned a fixable problem into
  /// an unexplained one.
  Future<void> _run(
    BuildContext context,
    String fallback,
    Future<OperationTrip?> Function(TripDetailsCubit cubit) action,
  ) async {
    final details = context.read<TripDetailsCubit>();
    final list = context.read<TripsListCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final updated = await action(details);
    if (updated != null) {
      list.updateTripInList(updated);
      return;
    }
    final state = details.state;
    final message = state is TripDetailsLoaded ? state.lastError : null;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message?.isNotEmpty == true ? message! : fallback),
        duration: const Duration(seconds: 6),
      ),
    );
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
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
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
              borderRadius: BorderRadius.circular(AppTokens.radius),
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
                        tripFriendlyDate(trip.date),
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
                              DashboardIcons.transition,
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
                    'من ${passenger.pickup} إلى ${passenger.dropoff}',
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
        Expanded(child: TripSeatMap(trip: trip)),
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
        borderRadius: BorderRadius.circular(AppTokens.radius),
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
            color: tripSeatColor(context, state),
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

String _actionLabel(OperationTripStatus status) {
  return switch (status) {
    OperationTripStatus.openForBooking => 'فتح الحجز',
    OperationTripStatus.boarding => 'بدء صعود الركاب',
    OperationTripStatus.inProgress => 'بدء الرحلة',
    OperationTripStatus.completed => 'إنهاء الرحلة',
    _ => status.label,
  };
}

String _listTitle(String filter) {
  return switch (filter) {
    'today' => 'رحلات اليوم',
    'active' => 'الرحلات قيد التشغيل',
    'upcoming' => 'الرحلات القادمة',
    'completed' => 'الرحلات المكتملة',
    'stale' => 'رحلات فات موعدها وما زالت مفتوحة',
    _ => 'كل الرحلات',
  };
}
