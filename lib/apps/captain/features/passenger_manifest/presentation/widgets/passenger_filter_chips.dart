import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_state.dart';
import 'passenger_status_presentation.dart';

/// The manifest's filters, as the design draws them: a scrolling row of pills,
/// each stating how many rows it would leave on screen.
///
/// The count is the reason this is worth the space. Without it the captain taps
/// "غائب" to find out whether anyone is missing; with it they already know, and
/// the tap is only to act on the ones who are.
class PassengerFilterChips extends StatelessWidget {
  const PassengerFilterChips({
    super.key,
    required this.current,
    required this.counts,
    required this.onSelect,
  });

  final PassengerBoardingStatus? current;
  final PassengerCounts counts;
  final ValueChanged<PassengerBoardingStatus> onSelect;

  int _countFor(PassengerBoardingStatus status) => switch (status) {
    PassengerBoardingStatus.boarded => counts.boarded,
    PassengerBoardingStatus.pending => counts.pending,
    PassengerBoardingStatus.absent => counts.absent,
    PassengerBoardingStatus.cancelled => counts.cancelled,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(
          CaptainDesignTokens.s16,
          CaptainDesignTokens.s8,
          CaptainDesignTokens.s16,
          CaptainDesignTokens.s8,
        ),
        children: [
          for (final status in kFilterablePassengerStatuses)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: CaptainDesignTokens.s8,
              ),
              child: _Chip(
                label: status.label,
                count: _countFor(status),
                isActive: current == status,
                onSelect: () => onSelect(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onSelect,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? CaptainColors.onPrimary
        : CaptainColors.textPrimaryFor(context);

    return Semantics(
      selected: isActive,
      button: true,
      child: InkWell(
        onTap: onSelect,
        borderRadius: CaptainDesignTokens.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isActive
                ? CaptainColors.primary
                : CaptainColors.surfaceAltFor(context),
            borderRadius: CaptainDesignTokens.brPill,
            border: Border.all(
              color: isActive
                  ? CaptainColors.primary
                  : CaptainColors.borderFor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CaptainTypography.labelMedium(context).copyWith(
                  color: foreground,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              // A count is read left-to-right whatever the label around it.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '($count)',
                  style: CaptainTypography.labelMedium(context).copyWith(
                    color: foreground.withValues(alpha: isActive ? 0.85 : 0.6),
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
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
