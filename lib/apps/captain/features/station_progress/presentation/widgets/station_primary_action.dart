import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../domain/entities/station_action.dart';
import '../cubit/station_progress_cubit.dart';
import '../cubit/station_progress_state.dart';
import '../formatters/station_labels.dart';

/// The captain's one action, docked at the bottom of the trip screen.
///
/// A single button, always. A driver holding a wheel should never have to choose
/// between two controls, and there is genuinely only ever one right move: report
/// arriving, continue to the next station, or end the trip.
///
/// When the vehicle may not leave, the button is disabled **and the label
/// becomes the reason** — "متبقي راكبان", the only thing that ever holds a
/// vehicle at a station. The reason
/// deliberately does not go on a second line: the docked bar holds one height
/// across every state of the trip, because a bar that grows and shrinks reflows
/// the page under the captain's thumb at exactly the moment they are reaching
/// for it. One line, one height, and §20's "can I leave now?" answered on the
/// control itself.
class StationPrimaryAction extends StatelessWidget {
  const StationPrimaryAction({
    super.key,
    required this.action,
    required this.state,
    required this.now,
    required this.onComplete,
  });

  final StationAction action;
  final StationProgressState state;
  final DateTime now;

  /// Ending the trip is still the trip-level transition it always was; the
  /// station flow only decides *when* it becomes the right thing to offer.
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (state.isSubmitting) return const _Busy();

    return switch (action) {
      StationArriveAction() => _Action(
        label: StationLabels.arriveAction,
        icon: Icons.pin_drop_rounded,
        color: CaptainColors.primary,
        onPressed: () =>
            context.read<StationProgressCubit>().arriveAtCurrentStation(),
      ),

      StationDepartAction(:final station, :final gate) => _departAction(
        context,
        station: station,
        gate: gate,
      ),

      StationFinishAction() || StationBoardUnavailable() => _Action(
        label: 'إنهاء الرحلة',
        icon: Icons.check_circle_rounded,
        color: CaptainColors.primary,
        onPressed: () => _confirmComplete(context),
      ),
    };
  }

  Widget _departAction(
    BuildContext context, {
    required TripStation station,
    required StationGate gate,
  }) {
    if (gate.canDepart) {
      return _Action(
        label: StationLabels.departAction(_isLastStation(station)),
        icon: Icons.arrow_forward_rounded,
        color: CaptainColors.primary,
        // Leaving with everyone aboard is the normal case and stays one tap.
        // Leaving *before* the minute the riders here were published is not
        // refused — nobody is left behind — but it is confirmed, because it is
        // a decision rather than the flow of the trip.
        onPressed: gate.aheadOfSchedule
            ? () => _confirmEarlyDeparture(context, gate)
            : () => context.read<StationProgressCubit>().departCurrentStation(),
      );
    }

    return _Action(
      label:
          StationLabels.gateDetail(gate, now) ??
          StationLabels.gateHeadline(gate),
      icon: Icons.people_alt_rounded,
      color: CaptainColors.primary,
      onPressed: null,
    );
  }

  Future<void> _confirmEarlyDeparture(
    BuildContext context,
    StationGate gate,
  ) async {
    final cubit = context.read<StationProgressCubit>();
    final hint = StationLabels.earlyDepartureHint(gate, now);

    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'المغادرة قبل الموعد',
      message: hint == null
          ? 'صعد جميع ركاب هذه المحطة. هل تريد المغادرة الآن؟'
          : 'صعد جميع ركاب هذه المحطة، والمغادرة الآن $hint. '
                'هل تريد المتابعة؟',
      confirmLabel: 'نعم، تحرك الآن',
      confirmColor: CaptainColors.primary,
    );
    if (confirmed) await cubit.departCurrentStation();
  }

  bool _isLastStation(TripStation station) =>
      state.board.stations.isNotEmpty &&
      state.board.stations.last.id == station.id;

  Future<void> _confirmComplete(BuildContext context) async {
    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'إنهاء الرحلة',
      confirmColor: CaptainColors.primary,
    );
    if (confirmed) onComplete();
  }
}

/// Sized for a driver: full width, one large touch target, one line.
class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = enabled
        ? color
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = enabled
        ? Colors.white
        : CaptainColors.textSecondaryFor(context);

    return SizedBox(
      height: stationActionHeight(context),
      child: Material(
        color: background,
        borderRadius: CaptainDesignTokens.br16,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CaptainDesignTokens.br16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: foreground),
              const SizedBox(width: CaptainDesignTokens.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CaptainTypography.titleMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900, color: foreground),
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

/// Shared with the trip-level action so the bar is the same height whichever of
/// the two is rendering.
double stationActionHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(56).clamp(56.0, 96.0);

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: stationActionHeight(context),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
