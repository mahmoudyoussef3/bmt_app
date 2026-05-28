import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _selectedSeat;

  @override
  Widget build(BuildContext context) {
    final seats = [
      ('1', SeatStatus.available),
      ('2', SeatStatus.reserved),
      ('3', SeatStatus.available),
      ('4', SeatStatus.available),
      ('5', SeatStatus.available),
      ('6', SeatStatus.reserved),
      ('7', SeatStatus.available),
      ('8', SeatStatus.available),
      ('9', SeatStatus.available),
      ('10', SeatStatus.available),
      ('11', SeatStatus.reserved),
      ('12', SeatStatus.available),
    ];

    final availableCount = seats
        .where((seat) => seat.$2 == SeatStatus.available)
        .length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context, availableCount),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'FRONT',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 18),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                          children: [
                            for (final seat in seats)
                              SeatWidget(
                                id: seat.$1,
                                status: seat.$2 == SeatStatus.reserved
                                    ? SeatStatus.reserved
                                    : seat.$1 == _selectedSeat
                                    ? SeatStatus.selected
                                    : SeatStatus.available,
                                onTap: seat.$2 == SeatStatus.reserved
                                    ? null
                                    : () => setState(
                                        () => _selectedSeat =
                                            _selectedSeat == seat.$1
                                            ? null
                                            : seat.$1,
                                      ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _Legend(text: 'Available', color: Colors.white),
                            _Legend(text: 'Selected', color: Colors.blue),
                            _Legend(text: 'Reserved', color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (_selectedSeat != null)
                    AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Seat',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Seat $_selectedSeat',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Departure',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '8:40 AM',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: _selectedSeat == null
                        ? 'Select a Seat'
                        : 'Confirm Booking',
                    onPressed: _selectedSeat == null
                        ? () {}
                        : () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int availableCount) {
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
                'Select Your Seat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$availableCount seats available',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String text;
  final Color color;

  const _Legend({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black.withAlpha(26)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
