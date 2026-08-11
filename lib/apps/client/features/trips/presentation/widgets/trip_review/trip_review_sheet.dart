import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_error.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_form.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_loading.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_submitted_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_sheet_grabber.dart';

class TripReviewSheet extends StatelessWidget {
  const TripReviewSheet({super.key, required this.trip});

  final ReviewableTrip trip;

  @override
  Widget build(BuildContext context) {
    
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TripSheetGrabber(),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: BlocBuilder<TripReviewCubit, TripReviewState>(
                    builder: (context, state) => _body(state),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(TripReviewState state) {
    return switch (state) {
      TripReviewLoading() => const TripReviewLoadingView(),
      TripReviewLoadFailure(:final failure) => TripReviewErrorView(
        failure: failure,
      ),
      TripReviewEditing() => TripReviewForm(trip: trip, state: state),
      TripReviewSubmitted(:final review) => TripReviewSubmittedView(
        trip: trip,
        review: review,
      ),
    };
  }
}
