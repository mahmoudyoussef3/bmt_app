import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';

/// The one thing the trip's current status says to do next.
class TripExecutionPrimaryAction extends StatelessWidget {
  const TripExecutionPrimaryAction({
    super.key,
    required this.status,
    required this.tripId,
  });

  final TripExecutionStatus status;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      TripExecutionStatus.scheduled => _ActionButton(
        onPressed: () => context.read<TripExecutionCubit>().board(tripId),
        icon: Icons.people_alt_rounded,
        label: 'بدء صعود الركاب',
        color: CaptainColors.primary,
      ),
      TripExecutionStatus.boarding => _ActionButton(
        onPressed: () => context.read<TripExecutionCubit>().start(tripId),
        icon: Icons.play_circle_fill_rounded,
        label: 'بدء الرحلة',
        color: Colors.orange,
      ),
      TripExecutionStatus.inProgress => _ActionButton(
        onPressed: () => _confirmAndComplete(context),
        icon: Icons.check_circle_rounded,
        label: 'إنهاء الرحلة',
        color: CaptainColors.success,
      ),
      // A terminal state, not an action — disabled (not a live button that
      // silently does nothing) so it reads as "this trip is done" rather
      // than as a tappable control.
      TripExecutionStatus.completed ||
      TripExecutionStatus.cancelled => _TerminalLabel(status: status),
    };
  }

  /// Completing a trip is a terminal, irreversible transition — confirm
  /// before firing it so one mis-tap while driving can't end the trip.
  ///
  /// The `mounted` re-check matters: the captain can pop this screen while the
  /// dialog is up, and firing `complete` at a torn-down route would drive the
  /// cubit after it closed.
  Future<void> _confirmAndComplete(BuildContext context) async {
    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'إنهاء الرحلة',
      confirmColor: CaptainColors.success,
    );
    if (confirmed && context.mounted) {
      context.read<TripExecutionCubit>().complete(tripId);
    }
  }
}

class _TerminalLabel extends StatelessWidget {
  const _TerminalLabel({required this.status});

  final TripExecutionStatus status;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s16),
        shape: const RoundedRectangleBorder(
          borderRadius: CaptainDesignTokens.br16,
        ),
      ),
      child: Text(
        status == TripExecutionStatus.completed ? 'مكتملة' : 'ملغاة',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s20,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CaptainDesignTokens.br24,
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: CaptainTypography.titleMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}
