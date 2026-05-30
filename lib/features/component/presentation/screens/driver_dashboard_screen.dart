import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class CaptainDashboardScreen extends StatelessWidget {
  const CaptainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final passengers = [
      _Passenger(
        id: 1,
        name: 'Ahmed Hassan',
        pickup: 'Banha Center',
        dest: 'Smart Village',
        time: '8:30 AM',
        status: 'boarded',
      ),
      _Passenger(
        id: 2,
        name: 'Fatima Ali',
        pickup: 'Banha Station',
        dest: 'Smart Village',
        time: '8:30 AM',
        status: 'boarded',
      ),
      _Passenger(
        id: 3,
        name: 'Mohamed Karim',
        pickup: 'Banha Center',
        dest: 'Smart Village',
        time: '8:30 AM',
        status: 'boarded',
      ),
      _Passenger(
        id: 4,
        name: 'Noor Ibrahim',
        pickup: 'Banha Downtown',
        dest: 'Nasr City',
        time: '8:45 AM',
        status: 'arrived',
      ),
      _Passenger(
        id: 5,
        name: 'Hassan Youssef',
        pickup: 'Banha Station',
        dest: 'Smart Village',
        time: '9:00 AM',
        status: 'pending',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.route_rounded,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Captain Dashboard',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Banha → Smart Village route overview',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface.withAlpha(
                                            170,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const AppBadge(text: 'On time'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(
                              child: _StatTile(
                                label: 'Vehicle',
                                value: 'MT-2847',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                label: 'Route',
                                value: 'Banha → SV',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                label: 'Passengers',
                                value: '9/12',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(label: 'Progress', value: '75%'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const AppProgressBar(progress: 0.75),
                        const SizedBox(height: 8),
                        Text(
                          '8:40 AM - On Schedule',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withAlpha(170),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: passengers.length + 2,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'Passenger List',
                      style: Theme.of(context).textTheme.displaySmall,
                    );
                  }
                  if (index == passengers.length + 1) {
                    return const SizedBox(height: 90);
                  }
                  return _PassengerCard(passenger: passengers[index - 1]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withAlpha(34),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Stop',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Banha Downtown',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'in 5 minutes',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withAlpha(170),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Navigation',
                          outline: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Complete Trip',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(72),
            scheme.secondary.withAlpha(28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outline.withAlpha(110)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
                'Captain Dashboard',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(
                'Today\'s Route',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(170),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface.withAlpha(170),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Passenger {
  final int id;
  final String name;
  final String pickup;
  final String dest;
  final String time;
  final String status;

  const _Passenger({
    required this.id,
    required this.name,
    required this.pickup,
    required this.dest,
    required this.time,
    required this.status,
  });
}

class _PassengerCard extends StatelessWidget {
  final _Passenger passenger;

  const _PassengerCard({required this.passenger});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBoarded = passenger.status == 'boarded';
    final isArrived = passenger.status == 'arrived';
    final bgColor = isBoarded
        ? scheme.secondary.withAlpha(28)
        : isArrived
        ? scheme.primary.withAlpha(28)
        : scheme.surfaceContainerHighest.withAlpha(180);
    final statusColor = isBoarded
        ? scheme.secondary
        : isArrived
        ? scheme.primary
        : scheme.onSurface.withAlpha(170);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withAlpha(80)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(100)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${passenger.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passenger.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${passenger.pickup} → ${passenger.dest}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(170),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  passenger.time,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  passenger.status[0].toUpperCase() +
                      passenger.status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
