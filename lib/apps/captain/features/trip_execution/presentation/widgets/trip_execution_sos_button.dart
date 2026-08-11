import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

class TripExecutionSosButton extends StatefulWidget {
  const TripExecutionSosButton({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripExecutionSosButton> createState() => _TripExecutionSosButtonState();
}

class _TripExecutionSosButtonState extends State<TripExecutionSosButton> {
  static const _holdDuration = Duration(seconds: 3);
  static const _tick = Duration(milliseconds: 50);

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
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CaptainColors.error,
                  borderRadius: CaptainDesignTokens.br16,
                  boxShadow: [
                    BoxShadow(
                      color: CaptainColors.error.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              if (_progress > 0)
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: _progress.clamp(0, 1),
                    strokeWidth: 3,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
