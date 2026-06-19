import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/daily_booking_data.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_summary_card.dart';
import '../widgets/route_selection_tile.dart';
import '../widgets/time_selection_chip.dart';
import '../widgets/vehicle_card.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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
  void initState() {
    super.initState();
    context.read<BookingCubit>().loadDailyBookingData();
  }

  @override
  void dispose() {
    _step4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is DailyBookingLoaded) {
          _data = state.data;
        }

        if (state is BookingError && _data == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        final data = _data;
        if (data == null) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

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
                Expanded(child: _buildStep(context, data)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, DailyBookingData data) {
    switch (_step) {
      case 1:
        return _selectionList(
          title: AppLocalizations.of(context)!.booking_selectPickupPoint,
          items: data.pickupPoints,
          activeColor: Theme.of(context).colorScheme.primary,
          onSelect: (value) => setState(() {
            _pickup = value;
            _step = 2;
          }),
        );
      case 2:
        return _selectionList(
          title: AppLocalizations.of(context)!.booking_selectDestination,
          items: data.destinations,
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
            for (final time in data.arrivalTimes)
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ClientColors.surfaceSubtleFor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ClientColors.borderFor(context)),
              ),
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
                          AppLocalizations.of(
                            context,
                          )!.booking_availableVehicles,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.booking_pickBestShuttle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final vehicle in data.vehicles) ...[
              VehicleCard(
                id: vehicle.id,
                driver: vehicle.driver,
                time: vehicle.time,
                seatsLeft: vehicle.seatsLeft,
                occupancy: vehicle.occupancy,
                onBook: () => Navigator.of(context).pushNamed(
                  '/seat-selection',
                  arguments: {
                    'tripId': vehicle.id,
                    'driverName': vehicle.driver,
                    'departureTime': vehicle.time,
                    'pickupPoint': _pickup,
                    'destination': _destination,
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
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
                AppLocalizations.of(context)!.booking_bookYourRide,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                AppLocalizations.of(context)!.booking_stepOf4(_step),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
