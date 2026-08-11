import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_error_banner.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_ratings.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class TripReviewForm extends StatefulWidget {
  const TripReviewForm({super.key, required this.trip, required this.state});

  final ReviewableTrip trip;
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.trips_reviewFormTitle,
          style: ClientTypography.headingMedium(context),
        ),
        const SizedBox(height: 6),
        Text(
          widget.trip.reference,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 20),
        TripReviewRatings(trip: widget.trip, state: state),
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          maxLines: 3,
          maxLength: 1000,
          enabled: !state.isSubmitting,
          onChanged: cubit.writeComment,
          decoration: InputDecoration(
            hintText: context.l10n.trips_reviewCommentHint,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          TripReviewErrorBanner(failure: state.error!),
        ],
        const SizedBox(height: 20),
        ClientButton(
          label: state.isSubmitting
              ? context.l10n.trips_reviewSubmitting
              : context.l10n.trips_submitReviewButton,
          isLoading: state.isSubmitting,
          
          onPressed: state.canSubmit ? cubit.submit : null,
        ),
        if (!state.draft.isValid && !state.isSubmitting) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.trips_reviewIncompleteHint,
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
