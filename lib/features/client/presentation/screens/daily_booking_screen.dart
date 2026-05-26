import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/features/client/presentation/cubits/booking_cubit.dart';
import 'package:bmt_app/features/client/presentation/widgets/widgets.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class DailyBookingFlow extends StatefulWidget {
  const DailyBookingFlow({Key? key}) : super(key: key);

  @override
  State<DailyBookingFlow> createState() => _DailyBookingFlowState();
}

class _DailyBookingFlowState extends State<DailyBookingFlow> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        switch (state.step) {
          case BookingStep.location:
            return _SelectPickupLocation();
          case BookingStep.destination:
            return _SelectDestination();
          case BookingStep.arrival:
            return _SelectArrivalTime();
          case BookingStep.vehicles:
            return _SelectVehicle();
          case BookingStep.seats:
            return _SelectSeat();
          case BookingStep.confirmation:
            return _BookingConfirmation();
        }
      },
    );
  }
}

class _SelectPickupLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Pickup Location')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: MockData.locations.length,
                  itemBuilder: (context, index) {
                    final location = MockData.locations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LocationCard(
                        location: location,
                        onTap: () {
                          context.read<BookingCubit>().selectPickupLocation(
                            location,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectDestination extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Destination')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: MockData.locations.length,
                  itemBuilder: (context, index) {
                    final location = MockData.locations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LocationCard(
                        location: location,
                        onTap: () {
                          context.read<BookingCubit>().selectDestination(
                            location,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectArrivalTime extends StatelessWidget {
  final arrivalTimes = ['8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Arrival Time')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: arrivalTimes.length,
                  itemBuilder: (context, index) {
                    final time = arrivalTimes[index];
                    return ArrivalTimeButton(
                      label: time,
                      isSelected: false,
                      onTap: () {
                        // Create a DateTime with the selected time
                        final now = DateTime.now();
                        final timeParts = time.split(':');
                        final hour = int.parse(timeParts[0]);
                        final minute = int.parse(timeParts[1].split(' ')[0]);
                        final isPM = time.contains('PM');

                        final selectedTime = now.copyWith(
                          hour: isPM && hour != 12 ? hour + 12 : hour,
                          minute: minute,
                        );

                        context.read<BookingCubit>().selectArrivalTime(
                          selectedTime,
                        );
                        context.read<BookingCubit>().loadAvailableVehicles();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectVehicle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Vehicle')),
      body: SafeArea(
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: state.availableTrips.length,
                itemBuilder: (context, index) {
                  final trip = state.availableTrips[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VehicleCard(
                      vehicle: trip.vehicle,
                      trip: trip,
                      onBook: () {
                        context.read<BookingCubit>().selectVehicle(trip);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectSeat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final seats = state.selectedTrip?.vehicle.seats ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Select Your Seat')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Card(
                          color: AppTheme.primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '🚌 Front',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SeatGrid(
                            seats: seats,
                            onSeatSelected: (seat) {
                              context.read<BookingCubit>().selectSeat(seat);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.selectedSeat != null
                          ? () {
                              context.read<BookingCubit>().confirmBooking();
                            }
                          : null,
                      child: const Text('Confirm Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookingConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final booking = state.confirmedBooking!;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
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
                            child: Text('✅', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Booking Confirmed!',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: AppTheme.secondaryColor),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ConfirmationRow(
                                  label: 'Booking ID',
                                  value: booking.id,
                                ),
                                const SizedBox(height: 12),
                                _ConfirmationRow(
                                  label: 'Vehicle',
                                  value: booking.trip.vehicle.number,
                                ),
                                const SizedBox(height: 12),
                                _ConfirmationRow(
                                  label: 'Route',
                                  value:
                                      '${booking.trip.pickupLocation.name} → ${booking.trip.dropoffLocation.name}',
                                ),
                                const SizedBox(height: 12),
                                _ConfirmationRow(
                                  label: 'Departure',
                                  value: _formatDateTime(
                                    booking.trip.departureTime,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ConfirmationRow(
                                  label: 'Seat',
                                  value:
                                      'Row ${booking.seat.rowNumber}, Seat ${booking.seat.seatNumber}',
                                ),
                                const SizedBox(height: 12),
                                _ConfirmationRow(
                                  label: 'Price',
                                  value:
                                      'EGP ${booking.totalPrice.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<BookingCubit>().resetBooking();
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
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow({required this.label, required this.value});

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
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
