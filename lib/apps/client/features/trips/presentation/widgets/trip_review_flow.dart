import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_sheet.dart';

/// Post-trip review sheet: the passenger rates the captain, the vehicle, and
/// the route of a trip they actually took.
Future<void> showTripReviewFlow(
  BuildContext context, {
  required TripData trip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClientColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider<TripReviewCubit>(
      create: (_) => clientGetIt<TripReviewCubit>()..load(trip),
      child: TripReviewSheet(trip: trip),
    ),
  );
}
