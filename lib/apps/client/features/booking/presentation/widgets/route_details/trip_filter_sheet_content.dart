import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/trip_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/day_part.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/filter_bounds.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/trip_sort.dart';

/// Opens the filter sheet for Route Details' available-trips list — price,
/// seats, vehicle type, time of day, and sort, all backed by real per-trip
/// data (research.md §2).
Future<TripFilterCriteria?> showTripFilterSheet({
  required BuildContext context,
  required List<RouteTripOptionData> trips,
  required TripFilterCriteria criteria,
}) {
  return showClientBottomSheet<TripFilterCriteria>(
    context: context,
    builder: (_) => TripFilterSheetContent(trips: trips, initial: criteria),
  );
}

class TripFilterSheetContent extends StatefulWidget {
  const TripFilterSheetContent({
    super.key,
    required this.trips,
    required this.initial,
  });

  final List<RouteTripOptionData> trips;
  final TripFilterCriteria initial;

  @override
  State<TripFilterSheetContent> createState() => _TripFilterSheetContentState();
}

class _TripFilterSheetContentState extends State<TripFilterSheetContent> {
  late TripFilterCriteria _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = uniqueSortedValues(
      widget.trips.map((t) => t.vehicleType),
    );
    final priceBounds = numericBounds(
      widget.trips.map((t) => RouteFilterCriteria.parsePrice(t.price)),
    );
    final seatsBounds = numericBounds(
      widget.trips.map((t) => t.availableSeats),
    );
    final resultCount = widget.trips.where(_draft.matches).length;

    return FilterBottomSheet(
      title: 'Filter trips',
      resultCount: resultCount,
      canReset: _draft.activeCount > 0,
      onReset: () => setState(() => _draft = _draft.reset()),
      onApply: () => Navigator.of(context).pop(_draft),
      groups: [
        FilterRangeSlider(
          label: 'Price',
          values:
              _draft.priceRange ?? RangeValues(priceBounds.$1, priceBounds.$2),
          min: priceBounds.$1,
          max: priceBounds.$2,
          labelFormatter: (v) => '\$${v.round()}',
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(priceRange: v)),
        ),
        FilterRangeSlider(
          label: 'Available seats',
          values:
              _draft.seatsRange ?? RangeValues(seatsBounds.$1, seatsBounds.$2),
          min: seatsBounds.$1,
          max: seatsBounds.$2,
          labelFormatter: (v) => v.round().toString(),
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(seatsRange: v)),
        ),
        if (vehicleTypes.isNotEmpty)
          NullableFilterChipGroup(
            label: 'Vehicle type',
            options: vehicleTypes,
            selected: _draft.vehicleType,
            onSelected: (v) => setState(
              () => _draft = v == null
                  ? _draft.copyWith(clearVehicleType: true)
                  : _draft.copyWith(vehicleType: v),
            ),
          ),
        FilterChipGroup<DayPart?>(
          label: 'Time of day',
          options: const [null, ...DayPart.values],
          optionLabel: (value) => value == null ? 'Any' : timeOfDayLabel(value),
          selected: _draft.timeOfDay,
          onSelected: (v) => setState(
            () => _draft = v == null
                ? _draft.copyWith(clearTimeOfDay: true)
                : _draft.copyWith(timeOfDay: v),
          ),
        ),
        FilterChipGroup<TripSort>(
          label: 'Sort by',
          options: TripSort.values,
          optionLabel: tripSortLabel,
          selected: _draft.sort,
          onSelected: (v) => setState(() => _draft = _draft.copyWith(sort: v)),
        ),
      ],
    );
  }
}
