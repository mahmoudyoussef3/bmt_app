import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _step = 1;
  String _pickup = '';
  String _destination = '';
  String _time = '';
  String _seat = '';

  final pickupPoints = const [
    'Banha Station',
    'Banha Center',
    'Banha Downtown',
  ];
  final destinations = const ['Smart Village', 'Nasr City', 'Mohandessin'];
  final times = const ['8:30 AM', '9:00 AM', '9:30 AM'];
  final seats = const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: _step == 1 ? _setupForm(context) : _review(context),
            ),
            _step == 1 ? _continueButton(context) : _subscribeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _setupForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        _optionGroup(
          title: 'Pickup Point',
          items: pickupPoints,
          selected: _pickup,
          activeColor: Theme.of(context).colorScheme.primary,
          onSelect: (value) => setState(() => _pickup = value),
        ),
        const SizedBox(height: 18),
        _optionGroup(
          title: 'Destination',
          items: destinations,
          selected: _destination,
          activeColor: Theme.of(context).colorScheme.secondary,
          onSelect: (value) => setState(() => _destination = value),
        ),
        const SizedBox(height: 18),
        _timeGroup(context),
        const SizedBox(height: 18),
        _seatGroup(context),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final plans = [
      ('Monthly', '1,200', 'per month', null),
      ('Quarterly', '3,300', '3 months', 'Save 10%'),
      ('Yearly', '12,000', 'per year', 'Save 15%'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _pickup,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Destination',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _destination,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const AppSeparator(),
              Row(
                children: [
                  Expanded(
                    child: _reviewCell(context, 'Departure Time', _time),
                  ),
                  Expanded(child: _reviewCell(context, 'Reserved Seat', _seat)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Select Plan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final plan in plans) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.$1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(plan.$3, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EGP ${plan.$2}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (plan.$4 != null)
                      Text(
                        plan.$4!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text("What's Included", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        const _Benefit('Unlimited daily rides on your route'),
        const _Benefit('Reserved seat every day'),
        const _Benefit('Priority booking access'),
        const _Benefit('24/7 customer support'),
        const _Benefit('Flexible date adjustments'),
        const _Benefit('No cancellation fees'),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _optionGroup({
    required String title,
    required List<String> items,
    required String selected,
    required Color activeColor,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
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

  Widget _timeGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Arrival Time',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in times)
              ChoiceChip(
                label: Text(value),
                selected: _time == value,
                onSelected: (_) => setState(() => _time = value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _seatGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Seat', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in seats)
              ChoiceChip(
                label: Text(value),
                selected: _seat == value,
                onSelected: (_) => setState(() => _seat = value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _reviewCell(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
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
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _step == 1
                ? () => Navigator.of(context).maybePop()
                : () => setState(() => _step = 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _step == 1
                    ? 'Monthly Subscription'
                    : 'Confirm Your Subscription',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _step == 1
                    ? 'Setup your permanent route'
                    : 'Monthly plan details',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _continueButton(BuildContext context) {
    final canContinue =
        _pickup.isNotEmpty &&
        _destination.isNotEmpty &&
        _time.isNotEmpty &&
        _seat.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AppButton(
        label: 'Review Plans',
        onPressed: canContinue ? () => setState(() => _step = 2) : () {},
      ),
    );
  }

  Widget _subscribeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AppButton(
        label: 'Subscribe Now - EGP 1,200/month',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
