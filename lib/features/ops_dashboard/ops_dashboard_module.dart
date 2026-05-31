import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    return MultiBlocProvider(
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          // Narrow: phone / small tablet — use BottomNavigation
          if (w < 720) {
            final titles = ['Home', 'Tickets', 'Live'];
            return Scaffold(
              appBar: AppBar(title: Text(titles[_index])),
              body: _pages[_index],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.support_agent),
                    label: 'Tickets',
                  ),
                  BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Live'),
                ],
              ),
            );
          }

          // Wide: show NavigationRail + content
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: w < 1000
                    ? NavigationRailLabelType.selected
                    : NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.support_agent),
                    label: Text('Tickets'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.map),
                    label: Text('Live'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _pages[_index]),
            ],
          );
        },
      ),
    );
  }
}
