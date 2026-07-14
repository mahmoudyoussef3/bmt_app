import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_rating_card.dart';

class TripReviewForm extends StatefulWidget {
  const TripReviewForm({super.key, required this.trip, required this.state});

  final TripData trip;
  final TripReviewEditing state;

  @override
  State<TripReviewForm> createState() => _TripReviewFormState();
}

class _TripReviewFormState extends State<TripReviewForm> {
  late final TextEditingController _comment = TextEditingController(
    text: widget.state.draft.comment,
  );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripReviewCubit>();
    final state = widget.state;
    final trip = widget.trip;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Rate your trip', style: ClientTypography.headingMedium(context)),
        const SizedBox(height: 6),
        Text(
          trip.reference,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 20),
        TripReviewRatingCard(
          title: 'Driver rating',
          subtitle: trip.driverName,
          value: state.draft.driverRating,
          onChanged: cubit.rateDriver,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: 'Vehicle rating',
          subtitle: trip.vehicleName,
          value: state.draft.vehicleRating,
          onChanged: cubit.rateVehicle,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: 'Route rating',
          subtitle: trip.routeLine,
          value: state.draft.routeRating,
          onChanged: cubit.rateRoute,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          maxLines: 3,
          maxLength: 1000,
          enabled: !state.isSubmitting,
          onChanged: cubit.writeComment,
          decoration: InputDecoration(
            hintText: 'Share feedback (optional)',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          _ReviewErrorBanner(message: state.error!),
        ],
        const SizedBox(height: 20),
        ClientButton(
          label: state.isSubmitting ? 'Submitting…' : 'Submit review',
          isLoading: state.isSubmitting,
          // Stays disabled until all three ratings are set — the sheet never
          // submits stars the passenger did not choose.
          onPressed: state.canSubmit ? cubit.submit : null,
        ),
        if (!state.draft.isValid && !state.isSubmitting) ...[
          const SizedBox(height: 8),
          Text(
            'Give the driver, vehicle, and route a star rating to continue.',
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}

class _ReviewErrorBanner extends StatelessWidget {
  const _ReviewErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.journeyRedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.onJourneyRed),
            ),
          ),
        ],
      ),
    );
  }
}
