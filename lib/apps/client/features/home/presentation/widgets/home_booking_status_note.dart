import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';

/// Says what the status means and what happens next. A badge alone tells a
/// rider their payment is "under review" without telling them whether they
/// need to do anything — this strip closes that gap.
class HomeBookingStatusNote extends StatelessWidget {
  const HomeBookingStatusNote({super.key, required this.status});

  final HomeBookingStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = status.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: accent.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.explanation,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
