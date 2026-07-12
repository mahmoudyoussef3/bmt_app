import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';

/// A slowly breathing icon badge. Used where the captain is waiting on
/// operations, so the screen reads as "live" rather than stalled.
class CaptainPulseBadge extends StatefulWidget {
  const CaptainPulseBadge({super.key, required this.icon});

  final IconData icon;

  @override
  State<CaptainPulseBadge> createState() => _CaptainPulseBadgeState();
}

class _CaptainPulseBadgeState extends State<CaptainPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(size: 108 + 24 * t, alpha: 0.05 + 0.03 * (1 - t)),
              _ring(size: 92 + 12 * t, alpha: 0.10),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              CaptainColors.primary,
              CaptainColors.primary.withValues(alpha: 0.75),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          boxShadow: [
            BoxShadow(
              color: CaptainColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(widget.icon, size: 36, color: Colors.white),
      ),
    );
  }

  Widget _ring({required double size, required double alpha}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CaptainColors.primary.withValues(alpha: alpha),
      ),
    );
  }
}
