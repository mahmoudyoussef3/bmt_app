import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_summary_cards.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_tab_bar.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_analytics_charts.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/screens/fleet_drivers_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/screens/fleet_vehicles_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

class FleetOverviewScreen extends StatefulWidget {
  final FleetTab? initialTab;
  const FleetOverviewScreen({super.key, this.initialTab});

  @override
  State<FleetOverviewScreen> createState() => _FleetOverviewScreenState();
}

class _FleetOverviewScreenState extends State<FleetOverviewScreen> {
  late FleetTab _activeTab;
  bool _isListMode = true;

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

          return SingleChildScrollView(
            key: ValueKey('scroll-${_activeTab.name}-list-$_isListMode'),
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isListMode) ...[
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.large),
                  FleetSummaryCards(summary: workspace.summary),
                  const SizedBox(height: AppSpacing.large),
                  FleetAnalyticsCharts(workspace: workspace),
                  const SizedBox(height: AppSpacing.large),
                  FleetTabBar(
                    active: _activeTab,
                    summary: workspace.summary,
                    onTabChanged: _changeTab,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey('tab-$_activeTab-list-$_isListMode'),
                    child: switch (_activeTab) {
                      FleetTab.drivers => MultiBlocProvider(
                        providers: [
                          BlocProvider<FleetDriversCubit>(
                            create: (_) =>
                                dashboardDi<FleetDriversCubit>()..load(),
                          ),
                          BlocProvider<FleetDocumentsCubit>(
                            create: (_) =>
                                dashboardDi<FleetDocumentsCubit>()..load(),
                          ),
                        ],
                        child: FleetDriversScreen(
                          onViewStateChanged: (isList) =>
                              setState(() => _isListMode = isList),
                        ),
                      ),
                      FleetTab.vehicles => MultiBlocProvider(
                        providers: [
                          BlocProvider<FleetVehiclesCubit>(
                            create: (_) =>
                                dashboardDi<FleetVehiclesCubit>()..load(),
                          ),
                          BlocProvider<FleetDocumentsCubit>(
                            create: (_) =>
                                dashboardDi<FleetDocumentsCubit>()..load(),
                          ),
                        ],
                        child: FleetVehiclesScreen(
                          onViewStateChanged: (isList) =>
                              setState(() => _isListMode = isList),
                        ),
                      ),
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const DashboardLoading();
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardModuleHeader(
      icon: Icons.local_shipping_rounded,
      title: 'إدارة الأسطول',
      subtitle: 'تحكم في السائقين والمركبات والتعيينات والوثائق من مكان واحد.',
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
