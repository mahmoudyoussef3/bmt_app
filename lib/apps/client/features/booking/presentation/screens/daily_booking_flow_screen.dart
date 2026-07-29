import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/daily_booking_data.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/daily_booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/daily_booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_booking_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_booking_message.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_booking_progress.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_booking_step_view.dart';

/// A four-step wizard for booking a same-day ride.
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
  DailyBookingData? _data;

  @override
  void dispose() {
    _step4Controller.dispose();
    super.dispose();
  }

  void _back() => _step == 1
      ? Navigator.of(context).maybePop()
      : setState(() => _step -= 1);

  void _goTo(int step, {String? pickup, String? destination, String? time}) {
    setState(() {
      _step = step;
      if (pickup != null) _pickup = pickup;
      if (destination != null) _destination = destination;
      if (time != null) _time = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyBookingCubit, DailyBookingState>(
      builder: (context, state) {
        if (state is DailyBookingLoaded) _data = state.data;
        final data = _data;
        if (state is DailyBookingError && data == null) {
          return DailyBookingMessage(message: state.message);
        }
        if (data == null) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                DailyBookingHeader(
                  step: _step,
                  onBack: _back,
                  onRefresh: context.read<DailyBookingCubit>().load,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: DailyBookingProgress(step: _step),
                ),
                Expanded(
                  child: DailyBookingStepView(
                    step: _step,
                    data: data,
                    pickup: _pickup,
                    destination: _destination,
                    time: _time,
                    controller: _step4Controller,
                    onSelectPickup: (v) => _goTo(2, pickup: v),
                    onSelectDestination: (v) => _goTo(3, destination: v),
                    onSelectTime: (v) => _goTo(4, time: v),
                    onBook: _book,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _book(DailyBookingVehicle vehicle) {
    // This flow never fetched route points or trip pricing (it only lists
    // distinct pickup/destination city names and same-day vehicles), so the
    // route handed to the wizard is built entirely from what was selected
    // here: two stops in travel order and the one trip the rider tapped.
    final route = RouteOptionData(
      id: vehicle.id,
      routeName: '$_pickup - $_destination',
      pickup: _pickup,
      destination: _destination,
      distance: '',
      duration: '',
      availableSeats: vehicle.seatsLeft,
      startingPrice: '',
      priceRange: '',
      points: [
        RoutePointData(name: _pickup, order: 0),
        RoutePointData(name: _destination, order: 1),
      ],
      availableTrips: [
        RouteTripOptionData(
          id: vehicle.id,
          departureTime: vehicle.time,
          arrivalTime: _time,
          availableSeats: vehicle.seatsLeft,
          vehicleType: '',
          price: '',
        ),
      ],
    );
    Navigator.of(context).pushNamed(BookingRoutes.wizard, arguments: route);
  }
}
