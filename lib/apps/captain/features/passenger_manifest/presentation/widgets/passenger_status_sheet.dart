import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_cubit.dart';
import 'passenger_status_presentation.dart';

/// Asks the captain for a passenger's new boarding status.
///
/// The cubit is resolved from [context] — the page's context, above the sheet —
/// because the sheet is pushed onto the root navigator and so sits outside the
/// page's provider subtree.
Future<void> showPassengerStatusSheet(
  BuildContext context,
  Passenger passenger,
) {
  final cubit = context.read<PassengerManifestCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PassengerStatusSheet(
      passenger: passenger,
      onSelect: (status) {
        Navigator.pop(sheetContext);
        cubit.updateStatus(tripPassengerId: passenger.id, status: status);
      },
    ),
  );
}

class _PassengerStatusSheet extends StatelessWidget {
  const _PassengerStatusSheet({
    required this.passenger,
    required this.onSelect,
  });

  final Passenger passenger;
  final ValueChanged<PassengerBoardingStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r32),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetGrabber(),
          const SizedBox(height: CaptainDesignTokens.s24),
          Text(
            passenger.name,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'مقعد ${passenger.seat}',
            style: CaptainTypography.labelMedium(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Text(
            'تحديث الحالة',
            style: CaptainTypography.labelSmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          for (final status in kAssignablePassengerStatuses)
            _StatusOption(
              status: status,
              isActive: passenger.status == status,
              onTap: () => onSelect(status),
            ),
        ],
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: CaptainColors.dividerFor(context),
          borderRadius: CaptainDesignTokens.br8,
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  final PassengerBoardingStatus status;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: CaptainDesignTokens.s12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // The status already in force is not a choice to re-make.
          onTap: isActive ? null : onTap,
          borderRadius: CaptainDesignTokens.br16,
          child: Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withAlpha(20)
                  : CaptainColors.surfaceFor(context),
              borderRadius: CaptainDesignTokens.br16,
              border: Border.all(
                color: isActive ? color : CaptainColors.dividerFor(context),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status.icon,
                  color: isActive
                      ? color
                      : CaptainColors.textSecondaryFor(context),
                  size: 24,
                ),
                const SizedBox(width: CaptainDesignTokens.s12),
                Text(
                  status.label,
                  style: CaptainTypography.labelLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? color
                        : CaptainColors.textPrimaryFor(context),
                  ),
                ),
                const Spacer(),
                if (isActive) Icon(Icons.check_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
