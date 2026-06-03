import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/booking/vehicle_booking_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/booking_flow_scaffold.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/vehicle_compare_card.dart';

/// Compare and select from available vehicles before booking.
class VehicleListingScreen extends StatefulWidget {
  const VehicleListingScreen({super.key});

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  VehicleSortOption _sort = VehicleSortOption.recommended;
  String? _highlightedId;

  void _openDetails(VehicleDetailData vehicle) {
    Navigator.pushNamed(
      context,
      BookingRoutes.vehicleDetails,
      arguments: {
        'vehicleId': vehicle.id,
        ...BookingSearchQuery.of(context).toArguments(),
      },
    );
  }

  void _selectVehicle(VehicleDetailData vehicle) {
    Navigator.pushNamed(context, '/seat-selection');
  }

  @override
  Widget build(BuildContext context) {
    final query = BookingSearchQuery.of(context);
    final vehicles = sortVehicles(mockVehiclesForCompare(), _sort);

    return BookingFlowScaffold(
      title: 'Choose Your Vehicle',
      query: query,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionHeader(
            title: 'Compare vehicles',
            subtitle:
                '${vehicles.length} options · review comfort, driver & price',
          ),
          const SizedBox(height: 12),
          _SortBar(
            selected: _sort,
            onSelected: (option) => setState(() => _sort = option),
          ),
          const SizedBox(height: 16),
          ...vehicles.map((vehicle) {
            final highlighted = _highlightedId == vehicle.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: highlighted
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: VehicleCompareCard(
                  vehicle: vehicle,
                  onViewDetails: () => _openDetails(vehicle),
                  onSelect: () {
                    setState(() => _highlightedId = vehicle.id);
                    _selectVehicle(vehicle);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.selected, required this.onSelected});

  final VehicleSortOption selected;
  final ValueChanged<VehicleSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const options = [
      (VehicleSortOption.recommended, 'Recommended'),
      (VehicleSortOption.priceLow, 'Price'),
      (VehicleSortOption.rating, 'Rating'),
      (VehicleSortOption.seats, 'Seats'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((entry) {
          final active = selected == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.$2),
              selected: active,
              onSelected: (_) => onSelected(entry.$1),
              selectedColor: scheme.primary.withAlpha(50),
              checkmarkColor: scheme.primary,
              labelStyle: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
