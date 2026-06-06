import 'package:flutter/widgets.dart';

import '../../domain/entities/booking_search_query.dart';

BookingSearchQuery bookingQueryFromContext(BuildContext context) {
  return BookingSearchQuery.fromArguments(
    ModalRoute.of(context)?.settings.arguments,
  );
}
