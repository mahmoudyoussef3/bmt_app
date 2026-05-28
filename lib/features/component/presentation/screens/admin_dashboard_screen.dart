import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class DashboardWebScreen extends StatelessWidget {
  const DashboardWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Today's Metrics",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: const [
                      _MetricCard(
                        label: 'Active Vehicles',
                        value: '12',
                        trend: '+2',
                      ),
                      _MetricCard(
                        label: 'Total Bookings',
                        value: '156',
                        trend: '+18',
                      ),
                      _MetricCard(
                        label: 'Revenue',
                        value: 'EGP 4.2K',
                        trend: '+12%',
                      ),
                      _MetricCard(
                        label: 'Occupancy',
                        value: '87%',
                        trend: '+5%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Active Trips',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _tripCard(
                    context,
                    'MT-2847',
                    'Ahmed Mohamed',
                    'Banha → Smart Village',
                    '9/12',
                    0.75,
                    true,
                  ),
                  const SizedBox(height: 10),
                  _tripCard(
                    context,
                    'MT-2848',
                    'Karim Hassan',
                    'Banha → Nasr City',
                    '11/12',
                    0.65,
                    true,
                  ),
                  const SizedBox(height: 10),
                  _tripCard(
                    context,
                    'MT-2849',
                    'Mostafa Ali',
                    'Banha → Mohandessin',
                    '6/12',
                    0.25,
                    false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upcoming Trips',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _smallTrip(
                    context,
                    'MT-2850',
                    'Banha → Smart Village',
                    '9:30 AM',
                    '8 bookings',
                  ),
                  const SizedBox(height: 10),
                  _smallTrip(
                    context,
                    'MT-2851',
                    'Banha → October',
                    '10:00 AM',
                    '5 bookings',
                  ),
                  const SizedBox(height: 10),
                  _smallTrip(
                    context,
                    'MT-2852',
                    'Banha → Sheraton',
                    '10:30 AM',
                    '3 bookings',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fleet Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(
                        child: _FleetTile(label: 'Active', count: '12'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FleetTile(label: 'Maintenance', count: '2'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FleetTile(label: 'Idle', count: '1'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Trends',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _chartBar(context, 42, 'Mon'),
                          _chartBar(context, 30, 'Tue'),
                          _chartBar(context, 48, 'Wed'),
                          _chartBar(context, 34, 'Thu'),
                          _chartBar(context, 56, 'Fri'),
                          _chartBar(context, 46, 'Sat'),
                          _chartBar(context, 60, 'Sun'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: const [
                        Icon(Icons.warning_rounded, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Vehicle MT-2845 Needs Maintenance'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: const [
                        Icon(Icons.info_rounded, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(child: Text('High Traffic on Ring Road')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: const [
                        Icon(Icons.info_rounded, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(child: Text('Booking Cancellation Rate: 8%')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(label: 'View Detailed Report', onPressed: () {}),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Manage Fleet',
                    outline: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withAlpha(20),
            Colors.transparent,
          ],
        ),
        border: Border(bottom: BorderSide(color: Colors.black.withAlpha(15))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations Dashboard',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Operations Overview',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripCard(
    BuildContext context,
    String id,
    String driver,
    String route,
    String passengers,
    double progress,
    bool inTransit,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(driver, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              AppBadge(text: inTransit ? 'In Transit' : 'Picking Up'),
            ],
          ),
          const SizedBox(height: 8),
          Text(route, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                passengers,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).round()}% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(progress: progress),
        ],
      ),
    );
  }

  Widget _smallTrip(
    BuildContext context,
    String id,
    String route,
    String departure,
    String bookings,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(route, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                departure,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(bookings, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartBar(BuildContext context, double height, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              Text(
                trend,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _FleetTile extends StatelessWidget {
  final String label;
  final String count;

  const _FleetTile({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
