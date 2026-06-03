import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/booking_flow_scaffold.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/search_trip_card.dart';

/// Full-screen search trip form — entry to the booking search flow.
class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key, this.initialQuery});

  final BookingSearchQuery? initialQuery;

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  late BookingSearchQuery _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? const BookingSearchQuery();
  }

  Future<void> _pickLocation({
    required String title,
    required List<String> options,
    required String field,
  }) async {
    final current = field == 'pickup' ? _query.pickup : _query.destination;
    final value = await showHomePickerSheet(
      context: context,
      title: title,
      options: options,
      selected: current.isEmpty ? null : current,
    );
    if (value == null) return;
    setState(() {
      _query = field == 'pickup'
          ? _query.copyWith(pickup: value)
          : _query.copyWith(destination: value);
    });
  }

  void _search() {
    if (!_query.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select pickup and destination to continue'),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BookingFlowScaffold(
      title: 'Search Trip',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SearchTripCard(
            pickup: _query.pickup,
            destination: _query.destination,
            date: _query.date,
            time: _query.time,
            onPickupTap: () => _pickLocation(
              title: 'Pickup location',
              options: kPickupSuggestions,
              field: 'pickup',
            ),
            onDestinationTap: () => _pickLocation(
              title: 'Destination',
              options: kDestinationSuggestions,
              field: 'destination',
            ),
            onDateTap: () async {
              final value = await showHomePickerSheet(
                context: context,
                title: 'Select date',
                options: const [
                  'Today, Jun 3',
                  'Tomorrow, Jun 4',
                  'Fri, Jun 5',
                ],
                selected: _query.date,
              );
              if (value != null) {
                setState(() => _query = _query.copyWith(date: value));
              }
            },
            onTimeTap: () async {
              final value = await showHomePickerSheet(
                context: context,
                title: 'Select time',
                options: kTimeSuggestions,
                selected: _query.time.isEmpty ? null : _query.time,
              );
              if (value != null) {
                setState(() => _query = _query.copyWith(time: value));
              }
            },
            onSearch: _search,
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Other ways to search',
            subtitle: 'Browse or pick on map',
          ),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.all(4),
            onTap: () {
              Navigator.pushNamed(
                context,
                BookingRoutes.popularRoutes,
                arguments: _query.toArguments(),
              );
            },
            child: ListTile(
              leading: Icon(Icons.trending_up_rounded, color: scheme.primary),
              title: const Text('Popular Routes'),
              subtitle: const Text('Most used commutes in your network'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppSurface(
            padding: const EdgeInsets.all(4),
            onTap: () {
              Navigator.pushNamed(
                context,
                BookingRoutes.mapSelection,
                arguments: _query.toArguments(),
              );
            },
            child: ListTile(
              leading: Icon(Icons.map_rounded, color: scheme.secondary),
              title: const Text('Select on Map'),
              subtitle: const Text('Google Maps style picker (demo UI)'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
