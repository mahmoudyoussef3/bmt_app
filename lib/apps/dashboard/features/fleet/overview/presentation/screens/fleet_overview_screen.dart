import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_summary_cards.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_tab_bar.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/screens/fleet_drivers_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/screens/fleet_vehicles_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/screens/fleet_assignments_screen.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/screens/fleet_documents_screen.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FleetOverviewError) {
          return Center(child: Text('Error: ${state.message}'));
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
                  FleetTabBar(active: _activeTab, onTabChanged: _changeTab),
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
                      FleetTab.assignments =>
                        BlocProvider<FleetAssignmentsCubit>(
                          create: (_) =>
                              dashboardDi<FleetAssignmentsCubit>()..load(),
                          child: const FleetAssignmentsScreen(),
                        ),
                      FleetTab.documents => BlocProvider<FleetDocumentsCubit>(
                        create: (_) =>
                            dashboardDi<FleetDocumentsCubit>()..load(),
                        child: const FleetDocumentsScreen(),
                      ),
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary, scheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(34),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'Production Fleet Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'إدارة الأسطول',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'تحكم احترافي في السائقين، المركبات، التعيينات، الوثائق والصور من مكان واحد.',
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(230),
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ],
          );

          final actions = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withAlpha(130)),
            ),
            onPressed: () {
              debugPrint('[FleetOverviewScreen] Refresh workspace clicked');
              context.read<FleetOverviewCubit>().loadWorkspace();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث البيانات'),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: AppSpacing.large),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.large),
              actions,
            ],
          );
        },
      ),
    );
  }
}
