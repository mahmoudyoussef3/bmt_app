import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';

/// When the rider's plan starts running: the date of the trip they already
/// picked. This is a fact, not a control — a plan that starts on any other day
/// than the ride it was bought for would leave the first ride uncovered.
class PackageStartNote extends StatelessWidget {
  const PackageStartNote({super.key, required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);
    final label = date == null
        ? 'Your selected trip'
        : formatCalendarDay(context, date!);

    return BookingSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(ClientRadius.sm),
            ),
            child: Icon(Icons.calendar_month_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starts with your trip',
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The picked plan and its total, pinned above the wizard's primary action so
/// the rider never has to scroll back up to check what they are paying.
class PackageStepSummary extends StatelessWidget {
  const PackageStepSummary({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final plan = session.selectedPackage!;
    final name = plan.nameEn.trim().isEmpty ? plan.nameAr : plan.nameEn;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
        Text(
          'EGP ${session.totalPrice.toStringAsFixed(0)}',
          style: ClientTypography.priceSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
      ],
    );
  }
}

class PackageFaresError extends StatelessWidget {
  const PackageFaresError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: ClientColors.journeyRed,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load fares',
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 18),
            ClientButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
