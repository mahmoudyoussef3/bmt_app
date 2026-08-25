import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

/// Hold-to-call: a red disc that fills as it is held, and opens the emergency
/// report once it is full.
///
/// The design draws it as a circle rather than the rounded square everything
/// else on the bar uses, and that difference is the safety feature — it is the
/// one control the captain has to find by shape, without looking away from the
/// road. The fill sweeping across the disc is the progress indicator, so the
/// press target and the countdown are the same object.
class TripExecutionSosButton extends StatefulWidget {
  const TripExecutionSosButton({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripExecutionSosButton> createState() => _TripExecutionSosButtonState();
}

class _TripExecutionSosButtonState extends State<TripExecutionSosButton> {
  static const _holdDuration = Duration(seconds: 3);
  static const _tick = Duration(milliseconds: 50);
  static const _size = 56.0;

  double _progress = 0;
  Timer? _progressTimer;

  void _onLongPressStart(LongPressStartDetails _) {
    _progressTimer?.cancel();
    setState(() => _progress = 0);
    _progressTimer = Timer.periodic(_tick, (_) {
      setState(
        () => _progress += _tick.inMilliseconds / _holdDuration.inMilliseconds,
      );
      if (_progress >= 1) {
        _cancel();
        _triggerSos();
      }
    });
  }

  void _cancel() {
    _progressTimer?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  void _triggerSos() {
    if (!mounted) return;
    context.openReportIncident(
      widget.tripId,
      initialType: IncidentType.emergency,
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danger = CaptainColors.dangerFor(context);

    return Semantics(
      button: true,
      label: 'نداء استغاثة — اضغط مطولاً ثلاث ثوانٍ',
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: (_) => _cancel(),
        onLongPressCancel: _cancel,
        onTap: () => AppSnackbar.warning(
          context,
          'اضغط مطولاً 3 ثوانٍ لإرسال نداء الاستغاثة',
        ),
        child: Container(
          width: _size,
          height: _size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: danger,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: danger.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The fill sweeps from the leading edge as the hold progresses,
              // so the disc itself is the countdown.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Text(
                'SOS',
                style: CaptainTypography.labelLarge(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
