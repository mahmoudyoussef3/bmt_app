import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/kpi_card.dart';
import '../widgets/app_card.dart';
import '../cubit/kpi_cubit.dart';
import '../cubit/kpi_state.dart';


class OpsHomePage extends StatefulWidget {
  const OpsHomePage({super.key});

  @override
  State<OpsHomePage> createState() => _OpsHomePageState();
}

class _OpsHomePageState extends State<OpsHomePage> {
  @override
  void initState() {
    super.initState();
    // Load KPIs when the page is shown
    Future.microtask(() => context.read<KpiCubit>().loadKpis());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operations Home')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // KPI row
            SizedBox(
              height: 100,
              child: BlocBuilder<KpiCubit, KpiState>(
                builder: (context, state) {
                  if (state is KpiLoading) return const Center(child: CircularProgressIndicator());
                  if (state is KpiError) return Center(child: Text('Error: ${state.message}'));
                  final kpis = (state as KpiLoaded).kpis;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kpis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final k = kpis[i];
                      final mapped = _mapKpiToStyle(k.id);
                      return SizedBox(width: 220, child: KpiCard(title: k.label, value: k.value, color: mapped['color'] as Color, icon: mapped['icon'] as IconData));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  AppCard(title: 'Alerts', child: Text('No critical alerts')),
                  AppCard(title: 'Quick Actions', child: Wrap(spacing: 8, children: [ElevatedButton(onPressed: null, child: Text('Open Ticket')), ElevatedButton(onPressed: null, child: Text('Assign Driver'))])),
                  AppCard(title: 'Active Drivers', child: Text('120 online')),
                  AppCard(title: 'Incidents', child: Text('2 ongoing')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Map<String, Object> _mapKpiToStyle(String id) {
    switch (id) {
      case 'active_trips':
        return {'color': Colors.blue, 'icon': Icons.directions_bus};
      case 'delayed_trips':
        return {'color': Colors.orange, 'icon': Icons.timer};
      case 'completed_today':
        return {'color': Colors.green, 'icon': Icons.check_circle};
      case 'cancelled_bookings':
        return {'color': Colors.red, 'icon': Icons.cancel};
      case 'active_drivers':
        return {'color': Colors.teal, 'icon': Icons.person};
      case 'revenue_today':
        return {'color': Colors.purple, 'icon': Icons.attach_money};
      default:
        return {'color': Colors.grey, 'icon': Icons.info};
    }
  }
}
