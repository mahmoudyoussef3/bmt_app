import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class DailyBookingFlowScreen extends StatefulWidget {
  const DailyBookingFlowScreen({super.key});

  @override
  State<DailyBookingFlowScreen> createState() => _DailyBookingFlowScreenState();
}

class _DailyBookingFlowScreenState extends State<DailyBookingFlowScreen> {
  int _step = 1;
  String _pickup = '';
  String _destination = '';
  String _time = '';

  final pickupPoints = const [
    'Banha Station',
    'Banha Center',
    'Banha Downtown',
    'Al-Sadat St',
  ];
  final destinations = const [
    'Smart Village',
    'Nasr City',
    'Mohandessin',
    'Maadi',
    'Sheraton',
    'October',
    'Metro Station',
  ];
  final arrivalTimes = const ['8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(4, (index) {
                  final active = index + 1 <= _step;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black.withAlpha(20),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _buildStep(context)),
            if (_step == 4) _bookingSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 1:
        return _selectionList(
          title: 'Select Pickup Point',
          items: pickupPoints,
          activeColor: Theme.of(context).colorScheme.primary,
          onSelect: (value) => setState(() {
            _pickup = value;
            _step = 2;
          }),
        );
      case 2:
        return _selectionList(
          title: 'Select Destination',
          items: destinations,
          activeColor: Theme.of(context).colorScheme.secondary,
          onSelect: (value) => setState(() {
            _destination = value;
            _step = 3;
          }),
        );
      case 3:
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            for (final time in arrivalTimes)
              AppCard(
                onTap: () => setState(() {
                  _time = time;
                  _step = 4;
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 4:
      default:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          children: [
            Text(
              'Available Vehicles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _vehicleCard(
              context,
              'MT-2847',
              'Ahmed Mohamed',
              '8:40 AM',
              4,
              0.75,
            ),
            const SizedBox(height: 10),
            _vehicleCard(context, 'MT-2848', 'Karim Hassan', '8:50 AM', 2, 0.9),
            const SizedBox(height: 10),
            _vehicleCard(context, 'MT-2849', 'Mostafa Ali', '9:05 AM', 6, 0.5),
            const SizedBox(height: 100),
          ],
        );
    }
  }

  Widget _selectionList({
    required String title,
    required List<String> items,
    required Color activeColor,
    required ValueChanged<String> onSelect,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final item in items) ...[
          AppCard(
            onTap: () => onSelect(item),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: activeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _vehicleCard(
    BuildContext context,
    String id,
    String driver,
    String time,
    int seats,
    double occupancy,
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
                    'Vehicle $id',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(driver, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const AppBadge(text: 'Available'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 14),
              Icon(
                Icons.event_seat_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$seats seats left',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Occupancy', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${(occupancy * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(progress: occupancy),
          const SizedBox(height: 12),
          AppButton(
            label: 'Book Now',
            onPressed: () => Navigator.of(context).pushNamed('/seat-selection'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
            onPressed: _step == 1
                ? () => Navigator.of(context).maybePop()
                : () => setState(() => _step -= 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Your Ride',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Step $_step of 4',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black.withAlpha(15))),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCell(label: 'From', value: _pickup),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCell(label: 'To', value: _destination),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCell(label: 'Time', value: _time),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
