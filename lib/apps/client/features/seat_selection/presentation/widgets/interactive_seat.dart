import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/seat_widget.dart';

/// Animated wrapper around the shared core seat widget.
class InteractiveSeat extends StatelessWidget {
  const InteractiveSeat({
    super.key,
    required this.id,
    required this.status,
    required this.onTap,
  });

  final String id;
  final SeatStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      scale: status == SeatStatus.selected ? 1.05 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutQuad,
        child: SeatWidget(id: id, status: status, onTap: onTap),
      ),
    );
  }
}
