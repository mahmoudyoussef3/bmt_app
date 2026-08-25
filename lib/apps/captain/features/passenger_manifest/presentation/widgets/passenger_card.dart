import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_card_details.dart';
import 'passenger_status_badge.dart';
import 'passenger_status_sheet.dart';

/// One row of the manifest, in the design's shape: seat, name, where they get
/// on, and — while they are still outstanding — the two buttons that resolve
/// them.
///
/// The old card put every action behind a pencil that opened a sheet, so
/// boarding a full vehicle was fourteen taps and fourteen sheets. Boarding is
/// the single most repeated action in the app; it belongs on the card. The
/// buttons disappear once the passenger is resolved, which keeps the settled
/// rows quiet and leaves the outstanding ones visibly unfinished.
class PassengerCard extends StatelessWidget {
  const PassengerCard({
    super.key,
    required this.passenger,
    required this.onCall,
  });

  final Passenger passenger;

  final VoidCallback? onCall;

  bool get _isPending => passenger.status == PassengerBoardingStatus.pending;

  bool get _canChangeStatus =>
      passenger.status != PassengerBoardingStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: CaptainDesignTokens.hairline(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SeatDisc(seat: passenger.seat),
              const SizedBox(width: 10),
              Expanded(child: PassengerCardDetails(passenger: passenger)),
              const SizedBox(width: CaptainDesignTokens.s8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PassengerStatusBadge(status: passenger.status),
                  if (!_isPending && _canChangeStatus) ...[
                    const SizedBox(height: 6),
                    _ChangeStatusButton(passenger: passenger),
                  ],
                ],
              ),
            ],
          ),
          if (_isPending) ...[
            const SizedBox(height: 11),
            _PendingActions(passenger: passenger, onCall: onCall),
          ],
        ],
      ),
    );
  }
}

/// The seat code, in the disc the design gives it.
///
/// A seat is an identifier printed on the vehicle in Latin characters, so it is
/// pinned LTR — RTL would render "1A" for seat A1 and send the captain to the
/// wrong row.
class _SeatDisc extends StatelessWidget {
  const _SeatDisc({required this.seat});

  final String seat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        shape: BoxShape.circle,
      ),
      child: Directionality(
        textDirection: CaptainTextDirection.ofIdentifier(seat),
        child: Text(
          seat.isEmpty ? '—' : seat,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.bodySmall(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({required this.passenger, required this.onCall});

  final Passenger passenger;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: Icons.check_rounded,
            label: 'صعد',
            background: CaptainColors.successFor(context),
            foreground: Colors.white,
            onTap: () => applyPassengerStatus(
              context,
              passenger,
              PassengerBoardingStatus.boarded,
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        Expanded(
          child: _ActionPill(
            icon: Icons.close_rounded,
            label: 'غياب',
            background: CaptainColors.surfaceAltFor(context),
            foreground: CaptainColors.dangerFor(context),
            onTap: () => applyPassengerStatus(
              context,
              passenger,
              PassengerBoardingStatus.absent,
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        _CallSquare(onCall: onCall),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.all(Radius.circular(11)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelMedium(context).copyWith(
                    color: foreground,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w800,
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

class _CallSquare extends StatelessWidget {
  const _CallSquare({required this.onCall});

  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final enabled = onCall != null;
    final tint = enabled
        ? CaptainColors.textPrimaryFor(context)
        : CaptainColors.textSecondaryFor(context).withValues(alpha: 0.4);

    return Tooltip(
      message: enabled ? 'اتصال' : 'لا يوجد رقم هاتف',
      child: InkWell(
        onTap: onCall,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CaptainColors.surfaceAltFor(context),
            borderRadius: const BorderRadius.all(Radius.circular(11)),
          ),
          child: Icon(Icons.call_rounded, size: 17, color: tint),
        ),
      ),
    );
  }
}

/// The way back for a row that is already resolved — the captain boarded the
/// wrong seat, or the passenger turned up after being marked absent.
class _ChangeStatusButton extends StatelessWidget {
  const _ChangeStatusButton({required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'تغيير الحالة',
      child: InkWell(
        onTap: () => showPassengerStatusSheet(context, passenger),
        borderRadius: CaptainDesignTokens.br12,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CaptainColors.surfaceAltFor(context),
            borderRadius: CaptainDesignTokens.br12,
          ),
          child: Icon(
            Icons.edit_rounded,
            size: 15,
            color: CaptainColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}
