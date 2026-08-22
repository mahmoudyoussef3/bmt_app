import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/trip_review_entry.dart';
import 'rating_stars.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// One passenger review. Reviews needing attention carry a red edge so they
/// are findable by eye in a long, otherwise-uniform list.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final TripReviewEntry review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final flagged = review.needsAttention;

    return AppCard(
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: flagged
                  ? context.status(AppStatusTone.error).accent
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: EdgeInsetsDirectional.only(
          start: flagged ? AppSpacing.medium : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(review: review, flagged: flagged),
            const SizedBox(height: AppSpacing.small),
            Text(
              '${review.routeLabel} · ${review.vehicleName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.large,
              runSpacing: AppSpacing.small,
              children: [
                RatingStars(label: 'السائق', rating: review.driverRating),
                RatingStars(label: 'المركبة', rating: review.vehicleRating),
                RatingStars(label: 'المسار', rating: review.routeRating),
              ],
            ),
            if (review.hasComment) ...[
              const SizedBox(height: AppSpacing.medium),
              _Comment(comment: review.comment.trim()),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.review, required this.flagged});

  final TripReviewEntry review;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'الكابتن: ${review.driverName} · ${review.bookingNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (flagged)
              DashboardStatusChip(
                label: 'تحتاج متابعة',
                color: context.status(AppStatusTone.error).tint,
                textColor: context.status(AppStatusTone.error).ink,
              )
            else
              Text(
                review.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ratingColor(context, review.averageRating),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _formatDate(review.createdAt),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m · $hh:$mm';
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(comment, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
