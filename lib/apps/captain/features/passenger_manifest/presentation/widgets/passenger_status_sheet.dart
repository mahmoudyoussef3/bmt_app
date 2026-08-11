import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/widgets/no_show_reason_sheet.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_cubit.dart';
import 'passenger_status_presentation.dart';

Future<void> showPassengerStatusSheet(
  BuildContext context,
  Passenger passenger,
) async {
  final cubit = context.read<PassengerManifestCubit>();

  final status = await showModalBottomSheet<PassengerBoardingStatus>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PassengerStatusSheet(
      passenger: passenger,
      onSelect: (status) => Navigator.pop(sheetContext, status),
    ),
  );
  if (status == null || !context.mounted) return;

  // Boarding and un-boarding are the captain's own observation. Marking someone
  // absent takes a paying rider off the vehicle's obligation list, so it asks
  // for the same reason the station flow asks for — one no-show flow in the app,
  // matching the one no-show path in the database.
  if (status == PassengerBoardingStatus.absent) {
    final resolution = await showNoShowReasonSheet(
      context,
      passengerName: passenger.name,
      seatLabel: passenger.seat,
    );
    if (resolution == null) return;
    await cubit.updateStatus(
      tripPassengerId: passenger.id,
      status: status,
      noShowReason: resolution.reason,
      note: resolution.note,
    );
    return;
  }

  await cubit.updateStatus(tripPassengerId: passenger.id, status: status);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label,
                        style: CaptainTypography.labelLarge(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? color
                              : CaptainColors.textPrimaryFor(context),
                        ),
                      ),
                      if (status.confirmation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          status.confirmation,
                          style: CaptainTypography.bodySmall(context).copyWith(
                            color: CaptainColors.textSecondaryFor(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isActive) Icon(Icons.check_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
