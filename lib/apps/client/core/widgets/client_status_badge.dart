import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A colored status badge for trip and booking cards.
///
/// Uses [ClientColors.journeyBadge] to derive the correct background and text
/// colors from a [ClientJourneyStatus]. The dot indicator can be optionally
/// shown for currently-active states.
class ClientStatusBadge extends StatelessWidget {
  const ClientStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.showDot = false,
  });

  final ClientJourneyStatus status;
  final String label;

  /// When `true` a small pulsing dot is shown to the left of the label.
  /// Use for [ClientJourneyStatus.active] states only.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = ClientColors.journeyBadge(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _PulsingDot(color: colors.label),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: colors.fg),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha((128 + (_pulse.value * 127)).round()),
        ),
      ),
    );
  }
}
