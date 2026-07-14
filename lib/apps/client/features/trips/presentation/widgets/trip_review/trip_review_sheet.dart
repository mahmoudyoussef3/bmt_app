import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_form.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_submitted_view.dart';

class TripReviewSheet extends StatelessWidget {
  const TripReviewSheet({super.key, required this.trip});

  final ReviewableTrip trip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            const _SheetGrabber(),
            const SizedBox(height: 16),
            BlocBuilder<TripReviewCubit, TripReviewState>(
              builder: (context, state) => _body(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TripReviewState state) {
    return switch (state) {
      TripReviewLoading() => const _ReviewLoading(),
      TripReviewLoadFailure(:final message) => _ReviewError(message: message),
      TripReviewEditing() => TripReviewForm(trip: trip, state: state),
      TripReviewSubmitted(:final review) => TripReviewSubmittedView(
        trip: trip,
        review: review,
      ),
    };
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ClientColors.borderFor(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ReviewLoading extends StatelessWidget {
  const _ReviewLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Opening your review…',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(height: 12),
          Text(
            'We could not open your review',
            style: ClientTypography.headingSmall(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClientButton(
            label: 'Try again',
            onPressed: () => context.read<TripReviewCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
