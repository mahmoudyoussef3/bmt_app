import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «كل ما تحتاجه لإدارة مكتبك، في منصة واحدة» — eight module tiles flanking
/// the console they all report into.
class ModulesSection extends StatelessWidget {
  const ModulesSection({super.key});

  /// The width at which the two tile grids and the hub stop fitting on one
  /// line: 260 + 300 + 260 plus the two 16px gaps.
  static const _rowBreakpoint = 852.0;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      topBorder: true,
      bottomBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LandingContent.modulesHeadline,
            textAlign: TextAlign.center,
            style: LandingType.heading(
              landingClamp(context, min: 25, vw: 3.2, max: 40),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                LandingContent.modulesLead,
                textAlign: TextAlign.center,
                style: LandingType.lead(16).copyWith(height: 1.85),
              ),
            ),
          ),
          SizedBox(height: landingClamp(context, min: 30, vw: 4, max: 50)),
          LayoutBuilder(
            builder: (context, constraints) {
              const start = _ModuleGrid(points: LandingContent.modulesStart);
              const end = _ModuleGrid(points: LandingContent.modulesEnd);
              const hub = _ModulesHub();

              if (constraints.maxWidth < _rowBreakpoint) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    start,
                    SizedBox(height: 16),
                    Center(child: SizedBox(width: 300, child: hub)),
                    SizedBox(height: 16),
                    end,
                  ],
                );
              }
              // [ConstrainedBox] has no const constructor, so this row is
              // built rather than folded.
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: start,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(width: 300, child: hub),
                  const SizedBox(width: 16),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: end,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.points});

  final List<LandingPoint> points;

  @override
  Widget build(BuildContext context) {
    return LandingAutoGrid(
      minItemWidth: 140,
      spacing: 11,
      stagger: true,
      children: [for (final point in points) _ModuleTile(point: point)],
    );
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({required this.point});

  final LandingPoint point;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: _hovered ? LandingPalette.brandLine : LandingPalette.border,
          ),
          boxShadow: LandingPalette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.point.icon, size: 19, color: LandingPalette.brandInk),
            const SizedBox(height: 7),
            Text(
              widget.point.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// The navy hub the tiles point at, inside a slowly breathing dashed halo.
class _ModulesHub extends StatelessWidget {
  const _ModulesHub();

  @override
  Widget build(BuildContext context) {
    return Stack(
      // The halo sits 12px outside the card on every side; a [Stack] clips to
      // its own edge unless told otherwise, which would erase it entirely.
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -12,
          bottom: -12,
          left: -12,
          right: -12,
          child: IgnorePointer(child: _PulsingHalo()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: LandingPalette.navy,
            borderRadius: BorderRadius.circular(LandingRadii.card + 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x990B1B34),
                offset: Offset(0, 30),
                blurRadius: 60,
                spreadRadius: -28,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.space_dashboard_rounded,
                    size: 20,
                    color: LandingPalette.onNavyAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      LandingContent.modulesHubTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingType.metric(
                        15,
                        color: Colors.white,
                      ).copyWith(letterSpacing: 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LandingAutoGrid(
                minItemWidth: 110,
                spacing: 8,
                maxColumns: 2,
                children: [
                  for (final mini in LandingContent.modulesHubMini)
                    _HubMiniTile(mini: mini),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                LandingContent.modulesHubCaption,
                style: LandingType.label(
                  11.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubMiniTile extends StatelessWidget {
  const _HubMiniTile({required this.mini});

  final LandingMini mini;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mini.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              10,
              color: Colors.white.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            mini.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.metric(
              16,
              color: Colors.white,
            ).copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

/// `animation: ewtpulse 3.6s ease-in-out infinite` — a dashed outline that
/// fades between 28% and 85%.
class _PulsingHalo extends StatefulWidget {
  const _PulsingHalo();

  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
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
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return CustomPaint(
          painter: _DashedOutline(opacity: 0.28 + (0.85 - 0.28) * t),
        );
      },
    );
  }
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(LandingRadii.card + 14),
        ),
      );
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 6).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + 5;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = LandingPalette.brandLine.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_DashedOutline oldDelegate) =>
      oldDelegate.opacity != opacity;
}
