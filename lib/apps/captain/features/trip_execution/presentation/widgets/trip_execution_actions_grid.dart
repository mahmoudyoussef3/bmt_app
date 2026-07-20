import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

/// Everything else the captain can do on this trip, scoped to its [stage].
///
/// Boarding passengers is done from the manifest ("الركاب"), where a captain
/// taps a name and sets it to صعد. There is no ticket QR to scan — clients are
/// never issued one — so the scanner tile that used to sit here opened a
/// camera that could not succeed at anything.
///
/// The rest follow the stage: reporting a position or a status update before
/// operations has even released the trip describes a journey that isn't
/// happening.
class TripExecutionActionsGrid extends StatelessWidget {
  const TripExecutionActionsGrid({
    super.key,
    required this.tripId,
    required this.stage,
  });

  final String tripId;
  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // Three across once there's room for it; phones stay at two.
      crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 3 : 2,
      mainAxisSpacing: CaptainDesignTokens.s16,
      crossAxisSpacing: CaptainDesignTokens.s16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        // The manifest is the boarding door: available from the moment there
        // are bookings to look at.
        _ActionTile(
          label: 'الركاب',
          icon: Icons.people_alt_rounded,
          onTap: () => context.openPassengerManifest(tripId),
        ),
        _ActionTile(
          label: 'التواصل',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => context.openChats(tripId),
        ),
        if (stage.isLive) ...[
          _ActionTile(
            label: 'إرسال الموقع',
            icon: Icons.my_location_rounded,
            onTap: () => context.openLocationUpdate(tripId),
          ),
          _ActionTile(
            label: 'تحديث الحالة',
            icon: Icons.sync_rounded,
            onTap: () => context.openStatusUpdate(tripId),
          ),
        ],
        if (!stage.isWaiting)
          _ActionTile(
            label: 'بلاغ طارئ',
            icon: Icons.report_problem_outlined,
            destructive: true,
            onTap: () => context.openReportIncident(tripId),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CaptainColors.error : CaptainColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainDesignTokens.br24,
        child: Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s16),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br24,
            border: Border.all(
              color: destructive
                  ? CaptainColors.error.withValues(alpha: 0.1)
                  : CaptainColors.dividerFor(context).withValues(alpha: 0.5),
            ),
            boxShadow: CaptainDesignTokens.softShadow(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              // Flexible so a larger text scale shrinks into whatever room
              // is left in the tile's fixed aspect-ratio height instead of
              // overflowing it; maxLines/ellipsis still apply within that.
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: destructive
                        ? CaptainColors.error
                        : CaptainColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
