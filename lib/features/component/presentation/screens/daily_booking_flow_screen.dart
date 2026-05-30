import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/widgets/route_selection_tile.dart';
import 'package:bmt_app/features/component/presentation/widgets/time_selection_chip.dart';
import 'package:bmt_app/features/component/presentation/widgets/vehicle_card.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking_summary_card.dart';

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
  final ScrollController _step4Controller = ScrollController();

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
                            : Theme.of(
                                context,
                              ).colorScheme.surface.withAlpha(40),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _buildStep(context)),
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
              TimeSelectionChip(
                time: time,
                onTap: () => setState(() {
                  _time = time;
                  _step = 4;
                }),
              ),
          ],
        );
      case 4:
      default:
        return ListView(
          controller: _step4Controller,
          primary: false,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            AppSurface(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(30),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Vehicles',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick the best shuttle for your trip',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            VehicleCard(
              id: 'MT-2847',
              driver: 'Ahmed Mohamed',
              time: '8:40 AM',
              seatsLeft: 4,
              occupancy: 0.75,
              onBook: () => Navigator.of(context).pushNamed('/seat-selection'),
            ),
            const SizedBox(height: 10),
            VehicleCard(
              id: 'MT-2848',
              driver: 'Karim Hassan',
              time: '8:50 AM',
              seatsLeft: 2,
              occupancy: 0.9,
              onBook: () => Navigator.of(context).pushNamed('/seat-selection'),
            ),
            const SizedBox(height: 10),
            VehicleCard(
              id: 'MT-2849',
              driver: 'Mostafa Ali',
              time: '9:05 AM',
              seatsLeft: 6,
              occupancy: 0.5,
              onBook: () => Navigator.of(context).pushNamed('/seat-selection'),
            ),
            const SizedBox(height: 16),
            BookingSummaryCard(
              pickup: _pickup,
              destination: _destination,
              time: _time,
            ),
            const SizedBox(height: 8),
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
          RouteSelectionTile(
            label: item,
            color: activeColor,
            onTap: () => onSelect(item),
          ),
          const SizedBox(height: 10),
        ],
      ],
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

  @override
  void dispose() {
    _step4Controller.dispose();
    super.dispose();
  }
}
