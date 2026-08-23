import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/trip_review_entry.dart';
import 'rating_stars.dart';

/// The full review, read-only — a table row only has room for a one-line
/// snippet of the comment, so the written feedback and all three sub-ratings
/// (driver, vehicle, route) live here.
void showReviewDetailsDialog(BuildContext context, TripReviewEntry review) {
  showDialog<void>(
    context: context,
    builder: (_) => ReviewDetailsDialog(review: review),
  );
}

class ReviewDetailsDialog extends StatelessWidget {
  const ReviewDetailsDialog({super.key, required this.review});

  final TripReviewEntry review;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(review: review),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InfoRow(label: 'رقم الحجز', value: review.bookingNumber),
                  _InfoRow(label: 'المسار', value: review.routeLabel),
                  _InfoRow(label: 'المركبة', value: review.vehicleName),
                  const SizedBox(height: AppSpacing.medium),
                  Wrap(
                    spacing: AppSpacing.large,
                    runSpacing: AppSpacing.small,
                    children: [
                      RatingStars(label: 'السائق', rating: review.driverRating),
                      RatingStars(
                        label: 'المركبة',
                        rating: review.vehicleRating,
                      ),
                      RatingStars(label: 'المسار', rating: review.routeRating),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (review.hasComment)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(90),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        review.comment.trim(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Text(
                      'لم يترك الراكب تعليقاً مكتوباً على هذه الرحلة.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.review});

  final TripReviewEntry review;

  @override
  Widget build(BuildContext context) {
    final flagged = review.needsAttention;
    final tone = context.status(
      flagged ? AppStatusTone.error : AppStatusTone.success,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  review.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الكابتن: ${review.driverName} · ${review.bookingNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          DashboardStatusChip(
            label: flagged
                ? 'تحتاج متابعة'
                : review.averageRating.toStringAsFixed(1),
            color: tone.tint,
            textColor: tone.ink,
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
