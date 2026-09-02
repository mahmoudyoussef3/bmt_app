import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// The "one platform" diagram: four module tiles, the console at the centre,
/// four more tiles. The console card carries a slow dashed pulse so the
/// composition reads as modules feeding a hub rather than nine flat cards.
class ModulesSection extends StatelessWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < 900;

    return LandingSection(
      topBorder: true,
      bottomBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LandingSectionIntro(
            headline: 'كل ما تحتاجه لإدارة مكتبك، في منصة واحدة',
            lead:
                'بدل ما تدير أجزاء منفصلة، EWT تجمع العملية كلها في مكان واحد.',
            align: TextAlign.center,
            center: true,
            maxWidth: 620,
          ),
          SizedBox(height: landingClamp(context, min: 30, vw: 4, max: 50)),
          if (stacked)
            Column(
              children: [
                _ModuleGrid(points: LandingContent.modulesStart),
                const SizedBox(height: 16),
                const _CoreCard(),
                const SizedBox(height: 16),
                _ModuleGrid(points: LandingContent.modulesEnd),
              ],
            )
          else
            // `justify-content:center` with three capped blocks — the two
            // module grids cap at 320 and the hub at 300, and the leftover
            // width stays as outer margin rather than pushing the groups to
            // the page edges.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _ModuleGrid(points: LandingContent.modulesStart),
                  ),
                ),
                const SizedBox(width: 28),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: const _CoreCard(),
                  ),
                ),
                const SizedBox(width: 28),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _ModuleGrid(points: LandingContent.modulesEnd),
                  ),
                ),
              ],
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
      maxColumns: 2,
      children: [for (final point in points) _ModuleTile(point: point)],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingHoverCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(point.icon, size: 19, color: LandingPalette.brandInk),
          const SizedBox(height: 7),
          Text(point.title, style: LandingType.cardTitle(13.5)),
        ],
      ),
    );
  }
}

/// The navy hub at the centre of the diagram.
class _CoreCard extends StatefulWidget {
  const _CoreCard();

  @override
  State<_CoreCard> createState() => _CoreCardState();
}

class _CoreCardState extends State<_CoreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      // The halo is inset -12px on every side; without this the Stack's
      // default hard edge clips it away entirely.
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -12,
          right: -12,
          top: -12,
          bottom: -12,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.28, end: 0.85).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: const CustomPaint(painter: _DashedHaloPainter()),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: LandingPalette.navy,
            borderRadius: BorderRadius.circular(LandingRadii.card + 4),
            boxShadow: [
              BoxShadow(
                color: LandingPalette.navy.withValues(alpha: 0.6),
                offset: const Offset(0, 30),
                blurRadius: 60,
                spreadRadius: -28,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Text(
                    'لوحة تحكم EWT',
                    style: LandingType.cardTitle(15, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LandingAutoGrid(
                minItemWidth: 100,
                spacing: 8,
                maxColumns: 2,
                children: [
                  for (final item in LandingContent.coreMini)
                    _CoreMiniTile(label: item.label, value: item.value),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                'المركز الذي تُدار منه العملية بالكامل',
                style: LandingType.label(
                  11.5,
                  color: Colors.white.withValues(alpha: 0.7),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoreMiniTile extends StatelessWidget {
  const _CoreMiniTile({required this.label, required this.value});

  final String label;
  final String value;

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
            label,
            style: LandingType.label(
              10,
              color: Colors.white.withValues(alpha: 0.66),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(value, style: LandingType.cardTitle(16, color: Colors.white)),
        ],
      ),
    );
  }
}

/// The pulsing dashed outline around the hub. `border: 1px dashed` has no
/// [Border] equivalent, so the rounded rectangle is walked and drawn in
/// 6-on / 5-off runs.
class _DashedHaloPainter extends CustomPainter {
  const _DashedHaloPainter();

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
        ..color = LandingPalette.brandLine,
    );
  }

  @override
  bool shouldRepaint(_DashedHaloPainter oldDelegate) => false;
}
