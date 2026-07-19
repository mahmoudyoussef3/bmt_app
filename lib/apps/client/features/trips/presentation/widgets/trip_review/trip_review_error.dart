import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review_failure.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/utils/trip_review_failure_label.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when the review sheet could not be opened, with a retry.
class TripReviewErrorView extends StatelessWidget {
  const TripReviewErrorView({super.key, required this.failure});

  final TripReviewFailure failure;

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
            context.l10n.trips_reviewOpenError,
            style: ClientTypography.headingSmall(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            tripReviewFailureLabel(context, failure),
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClientButton(
            label: context.l10n.common_tryAgain,
            onPressed: () => context.read<TripReviewCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
