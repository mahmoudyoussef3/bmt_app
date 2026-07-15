import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/filter_bounds.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_result_sort.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class RouteFilterSheetContent extends StatefulWidget {
  const RouteFilterSheetContent({
    super.key,
    required this.routes,
    required this.initial,
  });

  final List<PopularRouteListData> routes;
  final RouteFilterCriteria initial;

  @override
  State<RouteFilterSheetContent> createState() =>
      _RouteFilterSheetContentState();
}

class _RouteFilterSheetContentState extends State<RouteFilterSheetContent> {
  late RouteFilterCriteria _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final departures = uniqueSortedValues(widget.routes.map((r) => r.pickup));
    final destinations = uniqueSortedValues(
      widget.routes.map((r) => r.destination),
    );
    final priceBounds = numericBounds(
      widget.routes.map((r) => RouteFilterCriteria.parsePrice(r.startingPrice)),
    );
    final durationBounds = numericBounds(
      widget.routes.map(
        (r) => RouteFilterCriteria.parseDurationMinutes(r.averageDuration),
      ),
    );
    final resultCount = widget.routes.where(_draft.matches).length;

    return FilterBottomSheet(
      title: l10n.booking_filterRoutes,
      resultCount: resultCount,
      canReset: _draft.activeCount > 0,
      onReset: () => setState(() => _draft = _draft.reset()),
      onApply: () => Navigator.of(context).pop(_draft),
      groups: [
        FilterRangeSlider(
          label: l10n.booking_priceRange,
          values:
              _draft.priceRange ?? RangeValues(priceBounds.$1, priceBounds.$2),
          min: priceBounds.$1,
          max: priceBounds.$2,
          labelFormatter: (v) => '\$${v.round()}',
          onChanged: (values) =>
              setState(() => _draft = _draft.copyWith(priceRange: values)),
        ),
        FilterRangeSlider(
          label: l10n.packages_duration,
          values:
              _draft.durationRange ??
              RangeValues(durationBounds.$1, durationBounds.$2),
          min: durationBounds.$1,
          max: durationBounds.$2,
          labelFormatter: (v) => '${v.round()}m',
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(durationRange: v)),
        ),
        if (departures.isNotEmpty)
          NullableFilterChipGroup(
            label: l10n.booking_departure,
            options: departures,
            selected: _draft.pickup,
            onSelected: (v) => setState(
              () => _draft = v == null
                  ? _draft.copyWith(clearPickup: true)
                  : _draft.copyWith(pickup: v),
            ),
          ),
        if (destinations.isNotEmpty)
          NullableFilterChipGroup(
            label: l10n.common_destination,
            options: destinations,
            selected: _draft.destination,
            onSelected: (v) => setState(
              () => _draft = v == null
                  ? _draft.copyWith(clearDestination: true)
                  : _draft.copyWith(destination: v),
            ),
          ),
        FilterChipGroup<RouteResultSort>(
          label: l10n.booking_filterSortBy,
          options: RouteResultSort.values,
          optionLabel: (value) => routeResultSortLabel(context, value),
          selected: _draft.sort,
          onSelected: (value) =>
              setState(() => _draft = _draft.copyWith(sort: value)),
        ),
      ],
    );
  }
}
