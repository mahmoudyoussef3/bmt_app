import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

/// Raises an emergency, behind a deliberate three-second hold.
///
/// Stateful because it runs a hold timer and paints its own progress — local,
/// transient interaction state with no bearing on the trip, and nothing the
/// cubit should carry. A plain tap explains the gesture instead of firing:
/// an SOS is not something to trip over on a bumpy road.
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
    // A stray duplicate long-press-start (without an intervening end/cancel)
    // would otherwise leave the previous periodic timer running unreferenced
    // — never cancelled, ticking `_progress` up twice as fast.
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
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: (_) => _cancel(),
      onLongPressCancel: _cancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_progress > 0)
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 6,
                color: Colors.red,
                backgroundColor: Colors.red.withAlpha(60),
              ),
            ),
          FloatingActionButton.extended(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.sos_rounded, size: 24),
            label: const Text(
              'طوارئ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: () => AppSnackbar.warning(
              context,
              'اضغط مطولاً 3 ثوانٍ لإرسال نداء الاستغاثة',
            ),
          ),
        ],
      ),
    );
  }
}
