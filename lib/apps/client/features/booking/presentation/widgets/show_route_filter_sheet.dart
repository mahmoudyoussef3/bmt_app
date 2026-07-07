import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_filter_sheet_content.dart';

/// Opens the premium filter sheet for the routes discovery grid. Returns the
/// criteria to apply if the passenger taps "Show N results", or `null` if
/// they dismiss the sheet without applying.
Future<RouteFilterCriteria?> showRouteFilterSheet({
  required BuildContext context,
  required List<PopularRouteListData> routes,
  required RouteFilterCriteria criteria,
}) {
  return showClientBottomSheet<RouteFilterCriteria>(
    context: context,
    builder: (_) => RouteFilterSheetContent(routes: routes, initial: criteria),
  );
}
