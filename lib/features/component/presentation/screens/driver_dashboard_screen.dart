import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class CaptainDashboardScreen extends StatelessWidget {
  const CaptainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: _StatTile(label: 'Vehicle', value: 'MT-2847'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(label: 'Route', value: 'Banha → SV'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(label: 'Passengers', value: '9/12'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(label: 'Progress', value: '75%'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppProgressBar(progress: 0.75),
                  const SizedBox(height: 8),
                  Text(
                    '8:40 AM - On Schedule',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: passengers.length + 2,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'Passenger List',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  }
                  if (index == passengers.length + 1) {
                    return const SizedBox(height: 90);
                  }
                  return _PassengerCard(passenger: passengers[index - 1]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Stop',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Banha Downtown',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'in 5 minutes',
                                style: TextStyle(color: Colors.grey),
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
                'Captain Dashboard',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Today\'s Route',
                style: Theme.of(context).textTheme.bodySmall,
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
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
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
    final isBoarded = passenger.status == 'boarded';
    final isArrived = passenger.status == 'arrived';
    final bgColor = isBoarded
        ? Theme.of(context).colorScheme.secondary.withAlpha(15)
        : isArrived
        ? Theme.of(context).colorScheme.primary.withAlpha(15)
        : Theme.of(context).cardColor;
    final statusColor = isBoarded
        ? Theme.of(context).colorScheme.secondary
        : isArrived
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: statusColor.withAlpha(36),
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  passenger.time,
                  style: Theme.of(context).textTheme.bodySmall,
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
