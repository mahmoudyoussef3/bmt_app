import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'core/di/di.dart' as di;
import 'domain/repositories/support_ticket_repository.dart';
import 'presentation/cubit/support_ticket_cubit.dart';
import 'presentation/cubit/kpi_cubit.dart';
import 'domain/repositories/kpi_repository.dart';
import 'domain/repositories/trip_stream_repository.dart';
import 'domain/repositories/driver_stream_repository.dart';
import 'core/eventbus/live_event_bus.dart';
import 'presentation/pages/live_ops_page.dart';
import 'presentation/cubit/live_ops_cubit.dart';
import 'presentation/pages/support_ticket_list_page.dart';
import 'presentation/pages/home_page.dart';

class OpsDashboardModule extends StatelessWidget {
  const OpsDashboardModule({super.key});

  @override
  Widget build(BuildContext context) {
    di.registerOpsCenterDependencies();

    return Theme(
      data: AppTheme.darkTheme(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SupportTicketCubit(di.di<SupportTicketRepository>()),
          ),
          BlocProvider(
            create: (_) => KpiCubit(di.di<KpiRepository>())..loadKpis(),
          ),
          BlocProvider(
            create: (_) => LiveOpsCubit(
              tripRepo: di.di<TripStreamRepository>(),
              driverRepo: di.di<DriverStreamRepository>(),
              eventBus: di.di<LiveEventBus>(),
            ),
          ),
        ],
        child: const _OpsShell(),
      ),
    );
  }
}

class _OpsShell extends StatefulWidget {
  const _OpsShell({Key? key}) : super(key: key);

  @override
  State<_OpsShell> createState() => _OpsShellState();
}

class _OpsShellState extends State<_OpsShell> {
  int _index = 0;

  final _pages = const [OpsHomePage(), SupportTicketListPage(), LiveOpsPage()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final horizontalPadding = w < 900 ? 12.0 : 18.0;
          final verticalPadding = w < 900 ? 10.0 : 14.0;

          if (w < 720) {
            return Scaffold(
              body: _buildPageHost(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.support_agent_outlined),
                    selectedIcon: Icon(Icons.support_agent),
                    label: 'Tickets',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Live',
                  ),
                ],
              ),
            );
          }

          // Wide: show NavigationRail + content
          return Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.18),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outline.withOpacity(0.16),
                    ),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: _index,
                  extended: w >= 1200,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: w < 1200
                      ? NavigationRailLabelType.selected
                      : NavigationRailLabelType.none,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      'Ops',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(Icons.support_agent),
                      label: Text('Tickets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('Live'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPageHost(
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageHost({
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      );
                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(fade),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: _pages[_index],
                    ),
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
