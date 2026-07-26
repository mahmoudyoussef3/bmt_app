import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';

import '../../../domain/entities/pickup_plan.dart';

/// One rider under a pickup stop, with the boarding actions valid for their
/// current state — the captain can only make the transitions the manifest
/// allows, so an already-boarded rider is never offered "board" again.
class CaptainPickupRiderTile extends StatelessWidget {
  const CaptainPickupRiderTile({
    super.key,
    required this.rider,
    required this.isBusy,
    required this.onConfirm,
    required this.onAbsent,
    required this.onReset,
  });

  final PickupRider rider;
  final bool isBusy;
  final VoidCallback onConfirm;
  final VoidCallback onAbsent;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = switch (rider.status) {
      PassengerBoardingStatus.boarded => (
        CaptainColors.success,
        Icons.check_circle_rounded,
      ),
      PassengerBoardingStatus.absent => (
        CaptainColors.error,
        Icons.person_off_rounded,
      ),
      _ => (CaptainColors.primary, Icons.hourglass_top_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: CaptainColors.backgroundFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.dividerFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: CaptainDesignTokens.s8),
              Expanded(
                child: Text(
                  rider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (rider.seat.trim().isNotEmpty)
                _SeatChip(seat: rider.seat),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          if (isBusy)
            const _BusyRow()
          else if (rider.isPending)
            _PendingActions(onConfirm: onConfirm, onAbsent: onAbsent)
          else
            _ResolvedRow(rider: rider, onReset: onReset),
        ],
      ),
    );
  }
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({required this.onConfirm, required this.onAbsent});

  final VoidCallback onConfirm;
  final VoidCallback onAbsent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _ActionButton(
            label: 'تأكيد الصعود',
            icon: Icons.how_to_reg_rounded,
            filled: true,
            color: CaptainColors.success,
            onTap: onConfirm,
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        Expanded(
          child: _ActionButton(
            label: 'غائب',
            icon: Icons.person_off_rounded,
            filled: false,
            color: CaptainColors.error,
            onTap: onAbsent,
          ),
        ),
      ],
    );
  }
}

class _ResolvedRow extends StatelessWidget {
  const _ResolvedRow({required this.rider, required this.onReset});

  final PickupRider rider;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final label = rider.hasBoarded ? 'صعد إلى المركبة' : 'مُسجّل كغائب';
    final color = rider.hasBoarded ? CaptainColors.success : CaptainColors.error;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: CaptainTypography.bodySmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s12,
            ),
            minimumSize: const Size(0, 36),
          ),
          child: Text(
            'تراجع',
            style: CaptainTypography.bodySmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusyRow extends StatelessWidget {
  const _BusyRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        Text(
          'جارٍ الحفظ…',
          style: CaptainTypography.bodySmall(
            context,
          ).copyWith(color: CaptainColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: CaptainDesignTokens.br12,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CaptainDesignTokens.s8),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: CaptainDesignTokens.br12,
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: CaptainDesignTokens.s4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.bodySmall(context).copyWith(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.seat});

  final String seat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        'مقعد $seat',
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: CaptainColors.primary),
      ),
    );
  }
}
