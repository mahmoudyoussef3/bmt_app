import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/features/client/presentation/cubits/subscription_cubit.dart';
import 'package:bmt_app/features/client/presentation/widgets/widgets.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class MonthlySubscriptionScreen extends StatefulWidget {
  const MonthlySubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<MonthlySubscriptionScreen> createState() =>
      _MonthlySubscriptionScreenState();
}

class _MonthlySubscriptionScreenState extends State<MonthlySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Subscription'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Subscription'),
            Tab(text: 'My Subscription'),
          ],
        ),
      ),
      body: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [_NewSubscriptionTab(), _MySubscriptionTab()],
          );
        },
      ),
    );
  }
}

class _NewSubscriptionTab extends StatefulWidget {
  @override
  State<_NewSubscriptionTab> createState() => _NewSubscriptionTabState();
}

class _NewSubscriptionTabState extends State<_NewSubscriptionTab> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) {
        if (state.isSubmitted) {
          return _SubscriptionConfirmation(
            subscription: state.createdSubscription!,
          );
        }

        return Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text('Pickup Location'),
              content: _PickupLocationStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Dropoff Location'),
              content: _DropoffLocationStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Preferred Time'),
              content: _PreferredTimeStep(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Preferred Seat'),
              content: _PreferredSeatStep(),
              isActive: _currentStep >= 3,
            ),
          ],
        );
      },
    );
  }
}

class _PickupLocationStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your pickup location',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...MockData.locations.take(3).map((location) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LocationCard(
              location: location,
              onTap: () {
                context.read<SubscriptionCubit>().selectPickupLocation(
                  location,
                );
              },
              isSelected:
                  context.read<SubscriptionCubit>().state.pickupLocation?.id ==
                  location.id,
            ),
          );
        }),
      ],
    );
  }
}

class _DropoffLocationStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your dropoff location',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...MockData.locations.skip(2).take(4).map((location) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LocationCard(
              location: location,
              onTap: () {
                context.read<SubscriptionCubit>().selectDropoffLocation(
                  location,
                );
              },
              isSelected:
                  context.read<SubscriptionCubit>().state.dropoffLocation?.id ==
                  location.id,
            ),
          );
        }),
      ],
    );
  }
}

class _PreferredTimeStep extends StatelessWidget {
  final times = ['8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your preferred arrival time',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: times.length,
          itemBuilder: (context, index) {
            final time = times[index];
            return ArrivalTimeButton(
              label: time,
              isSelected: false,
              onTap: () {
                // Parse time and create DateTime
                final timeParts = time.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1].split(' ')[0]);
                final isPM = time.contains('PM');

                final selectedTime = DateTime.now().copyWith(
                  hour: isPM && hour != 12 ? hour + 12 : hour,
                  minute: minute,
                );

                context.read<SubscriptionCubit>().selectArrivalTime(
                  selectedTime,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PreferredSeatStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final seats = MockData.vehicles[0].seats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your preferred seat',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SeatGrid(
          seats: seats,
          onSeatSelected: (seat) {
            context.read<SubscriptionCubit>().selectPreferredSeat(seat);
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.read<SubscriptionCubit>().submitSubscription();
            },
            child: const Text('Subscribe'),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionConfirmation extends StatelessWidget {
  final MonthlySubscription subscription;

  const _SubscriptionConfirmation({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Monthly Subscription Created!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SubConfirmationRow(
                      label: 'Subscription ID',
                      value: subscription.id,
                    ),
                    const SizedBox(height: 12),
                    _SubConfirmationRow(
                      label: 'Route',
                      value:
                          '${subscription.pickupLocation.name} → ${subscription.dropoffLocation.name}',
                    ),
                    const SizedBox(height: 12),
                    _SubConfirmationRow(
                      label: 'Preferred Arrival',
                      value: _formatTime(subscription.preferredArrival),
                    ),
                    const SizedBox(height: 12),
                    _SubConfirmationRow(
                      label: 'Seat',
                      value:
                          'Row ${subscription.preferredSeat.rowNumber}, Seat ${subscription.preferredSeat.seatNumber}',
                    ),
                    const SizedBox(height: 12),
                    _SubConfirmationRow(
                      label: 'Monthly Price',
                      value:
                          'EGP ${subscription.monthlyPrice.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _SubConfirmationRow(
                      label: 'Start Date',
                      value:
                          '${subscription.startDate.day}/${subscription.startDate.month}/${subscription.startDate.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SubscriptionCubit>().reset();
                  Navigator.of(
                    context,
                  ).popUntil(ModalRoute.withName('/client-home'));
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _SubConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _SubConfirmationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _MySubscriptionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sub = MockData.monthlySubscription;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sub.isActive)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subscription Active',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Since ${sub.startDate.day}/${sub.startDate.month}/${sub.startDate.year}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Subscription Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRowSub(
                            icon: '📍',
                            label: 'Pickup',
                            value: sub.pickupLocation.name,
                          ),
                          const SizedBox(height: 12),
                          _DetailRowSub(
                            icon: '🎯',
                            label: 'Dropoff',
                            value: sub.dropoffLocation.name,
                          ),
                          const SizedBox(height: 12),
                          _DetailRowSub(
                            icon: '⏰',
                            label: 'Arrival Time',
                            value:
                                '${sub.preferredArrival.hour.toString().padLeft(2, '0')}:${sub.preferredArrival.minute.toString().padLeft(2, '0')}',
                          ),
                          const SizedBox(height: 12),
                          _DetailRowSub(
                            icon: '🪑',
                            label: 'Seat',
                            value:
                                'Row ${sub.preferredSeat.rowNumber}, Seat ${sub.preferredSeat.seatNumber}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: AppTheme.primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Price',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'EGP ${sub.monthlyPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cancel subscription feature coming soon',
                            ),
                          ),
                        );
                      },
                      child: const Text('Cancel Subscription'),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'No active subscription',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowSub extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailRowSub({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
