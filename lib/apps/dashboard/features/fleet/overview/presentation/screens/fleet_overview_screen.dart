import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_attention.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_activity_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_analytics_charts.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_needs_attention_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_summary_cards.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_tab_bar.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/screens/fleet_drivers_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/screens/fleet_vehicles_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

class FleetOverviewScreen extends StatefulWidget {
  final FleetTab? initialTab;
  const FleetOverviewScreen({super.key, this.initialTab});

  @override
  State<FleetOverviewScreen> createState() => _FleetOverviewScreenState();
}

class _FleetOverviewScreenState extends State<FleetOverviewScreen> {
  late FleetTab _activeTab;
  bool _isListMode = true;
  FleetFocusRequest? _focusDriverRequest;
  FleetFocusRequest? _focusVehicleRequest;

  /// True from the moment a "Needs Attention" row is tapped until the tab it
  /// jumped to has either opened the target's dialog or given up (target not
  /// found, or the tab failed to load). Drives [_FleetFocusLoadingOverlay] so
  /// the tap gets *some* immediate feedback instead of a silent wait while the
  /// destination tab loads its own data in the background.
  bool _focusPending = false;

  /// One identity per tab, kept across the browse↔focus layout flip below.
  ///
  /// Focusing a driver swaps this screen's entire layout (scrolling page →
  /// bounded pane), so the tab sits under a different widget before and after.
  /// Without a stable identity its element is thrown away on that flip —
  /// together with the very selection that asked for it — and the tab comes
  /// back in list mode inside a box with no scroll of its own, overflowing the
  /// viewport by the height of the list. A global key lets the same element
  /// move between the two branches instead, so the selection (and the tab's
  /// cubits, unreloaded) survives the swap.
  final Map<FleetTab, GlobalKey> _tabKeys = {
    for (final tab in FleetTab.values) tab: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? FleetTab.drivers;
  }

  void _changeTab(FleetTab tab) {
    setState(() {
      _activeTab = tab;
      _isListMode = true;
    });
  }

  /// Jumps from a "Needs Attention" row straight to that driver/vehicle's
  /// detail dialog — the direct `[Open vehicle]` / `[Open driver]` action the
  /// panel promises, not just a filtered list the operator still has to
  /// search.
  void _openAttentionTarget(FleetAttentionTarget type, String id) {
    setState(() {
      _isListMode = true;
      _focusPending = true;
      if (type == FleetAttentionTarget.driver) {
        _activeTab = FleetTab.drivers;
        _focusDriverRequest = FleetFocusRequest(id);
      } else {
        _activeTab = FleetTab.vehicles;
        _focusVehicleRequest = FleetFocusRequest(id);
      }
    });
  }

  /// Called by the active tab once it has either opened the target's dialog
  /// or given up looking for it. Idempotent — safe to call more than once.
  void _resolveFocusPending() {
    if (!_focusPending) return;
    setState(() => _focusPending = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetOverviewCubit, FleetOverviewState>(
      builder: (context, state) {
        if (state is FleetOverviewLoading) {
          return const DashboardLoading();
        }

        if (state is FleetOverviewError) {
          return DashboardErrorState(
            message: state.message,
            onRetry: () => context.read<FleetOverviewCubit>().loadWorkspace(),
          );
        }

        if (state is FleetOverviewLoaded) {
          final workspace = state.workspace;

          final tabContent = AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: _tabKeys[_activeTab],
              child: switch (_activeTab) {
                FleetTab.drivers => MultiBlocProvider(
                  providers: [
                    BlocProvider<FleetDriversCubit>(
                      create: (_) => dashboardDi<FleetDriversCubit>()..load(),
                    ),
                    BlocProvider<FleetDocumentsCubit>(
                      create: (_) => dashboardDi<FleetDocumentsCubit>(),
                    ),
                  ],
                  child: FleetDriversScreen(
                    focusRequest: _focusDriverRequest,
                    onFocusResolved: _resolveFocusPending,
                    onViewStateChanged: (isList) =>
                        setState(() => _isListMode = isList),
                  ),
                ),
                FleetTab.vehicles => MultiBlocProvider(
                  providers: [
                    BlocProvider<FleetVehiclesCubit>(
                      create: (_) => dashboardDi<FleetVehiclesCubit>()..load(),
                    ),
                    BlocProvider<FleetDocumentsCubit>(
                      create: (_) => dashboardDi<FleetDocumentsCubit>(),
                    ),
                  ],
                  child: FleetVehiclesScreen(
                    focusRequest: _focusVehicleRequest,
                    onFocusResolved: _resolveFocusPending,
                    onViewStateChanged: (isList) =>
                        setState(() => _isListMode = isList),
                  ),
                ),
              },
            ),
          );

          final Widget body;
          if (!_isListMode) {
            // A driver/vehicle is focused (full screen on mobile, split pane
            // on desktop): drop the page-level scroll and hand the tab its
            // real bounded height instead, so the master list and the detail
            // pane can each scroll on their own rather than being dragged
            // along a single shared page scroll.
            body = Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: tabContent,
            );
          } else {
            body = SingleChildScrollView(
              key: ValueKey('scroll-${_activeTab.name}'),
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.large),
                  FleetSummaryCards(summary: workspace.summary),
                  const SizedBox(height: AppSpacing.large),
                  FleetNeedsAttentionPanel(
                    items: buildFleetAttentionItems(workspace),
                    onOpenDriver: (id) =>
                        _openAttentionTarget(FleetAttentionTarget.driver, id),
                    onOpenVehicle: (id) =>
                        _openAttentionTarget(FleetAttentionTarget.vehicle, id),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  FleetTabBar(
                    active: _activeTab,
                    summary: workspace.summary,
                    onTabChanged: _changeTab,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  tabContent,
                  const SizedBox(height: AppSpacing.large),
                  FleetAnalyticsCharts(workspace: workspace),
                  const SizedBox(height: AppSpacing.large),
                  FleetActivityPanel(workspace: workspace),
                ],
              ),
            );
          }

          if (!_focusPending) return body;

          // Immediate feedback for a "Needs Attention" tap: the destination
          // tab may need a full network load before it can find and open the
          // target, which can take a couple of seconds and happens below the
          // fold from where the operator is looking. Without this the tap
          // reads as unresponsive rather than "working on it".
          return Stack(
            children: [
              body,
              const Positioned.fill(child: _FleetFocusLoadingOverlay()),
            ],
          );
        }

        return const DashboardLoading();
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardModuleHeader(
      icon: DashboardIcons.fleetActive,
      title: 'إدارة الأسطول',
      subtitle: 'تحكم في بيانات السائقين والمركبات ووثائقهم من مكان واحد.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.read<FleetOverviewCubit>().loadWorkspace(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
        ),
      ],
    );
  }
}

class _FleetFocusLoadingOverlay extends StatelessWidget {
  const _FleetFocusLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.scrim.withAlpha(60),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'جارٍ الفتح...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
