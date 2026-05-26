import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/features/client/presentation/cubits/bookings_list_cubit.dart';
import 'package:bmt_app/features/client/presentation/cubits/tracking_cubit.dart';
import 'package:bmt_app/features/client/presentation/widgets/widgets.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome back, ${MockData.currentUser.name}! 👋',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready for your commute?',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickActionCard(
                    icon: '🚗',
                    label: 'Daily Booking',
                    onTap: () {
                      Navigator.of(context).pushNamed('/daily-booking');
                    },
                  ),
                  _QuickActionCard(
                    icon: '📅',
                    label: 'Monthly',
                    onTap: () {
                      Navigator.of(context).pushNamed('/monthly-subscription');
                    },
                  ),
                  _QuickActionCard(
                    icon: '📍',
                    label: 'Track',
                    onTap: () {
                      Navigator.of(context).pushNamed('/track-vehicle');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Upcoming Bookings Section
              Text(
                'Your Upcoming Bookings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              BlocBuilder<BookingsListCubit, BookingsListState>(
                builder: (context, state) {
                  if (state.bookings.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('📭', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming bookings',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: state.bookings
                        .map(
                          (booking) => _UpcomingBookingCard(
                            booking: booking,
                            onTrack: () {
                              context.read<TrackingCubit>().loadTracking(
                                booking.trip,
                              );
                              Navigator.of(context).pushNamed('/track-vehicle');
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Monthly Subscription Info (if exists)
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Active Monthly Subscription',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${MockData.monthlySubscription.pickupLocation.name} → ${MockData.monthlySubscription.dropoffLocation.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'EGP ${MockData.monthlySubscription.monthlyPrice.toStringAsFixed(2)}/month',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTrack;

  const _UpcomingBookingCard({required this.booking, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    return TripCard(trip: booking.trip, onTap: onTrack);
  }
}
