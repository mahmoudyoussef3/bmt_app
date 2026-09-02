import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_device.dart';
import '../widgets/landing_layout.dart';

/// «لوحة التحكم» — the console itself on a navy band, with four working tabs.
///
/// The tabs are real state rather than decoration, and each one is a real
/// screen: the claim is that one console answers operations, trips, bookings
/// and money, and a reader who can click between those four and watch the
/// actual product redraw has been shown that, not told it.
///
/// The band used to synthesise KPI tiles, a trend line and a trip table out of
/// invented figures. It shows the captures instead — a screenshot cannot
/// promise a screen the product does not have, and numbers written beside a
/// real screen only contradict the ones inside it.
class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tab = LandingContent.dashboardTabs[_tab];

    return Container(
      width: double.infinity,
      color: LandingPalette.navy,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.76, -1.05),
                  radius: 1.0,
                  colors: [Color(0x4D2563EB), Color(0x002563EB)],
                  stops: [0, 0.65],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: landingClamp(context, min: 52, vw: 6.5, max: 96),
            ),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LandingSectionIntro(
                    eyebrow: 'لوحة التحكم',
                    eyebrowColor: LandingPalette.onNavyAccent,
                    headline: 'شوف مكتبك بالكامل من لوحة تحكم واحدة',
                    lead:
                        'كل رحلة، كل حجز، وكل رقم مهم — في شاشة واحدة تتابعها '
                        'في أي وقت.',
                    maxWidth: 660,
                    onDark: true,
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 24, vw: 3, max: 36),
                  ),
                  _TabRail(
                    selected: _tab,
                    onSelect: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 14),
                  // Caption and shot cross-fade together, so the line always
                  // describes the screen underneath it.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Column(
                      key: ValueKey(_tab),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tab.caption,
                          textAlign: TextAlign.center,
                          style: LandingType.label(
                            13,
                            color: Colors.white.withValues(alpha: 0.66),
                            weight: FontWeight.w600,
                          ).copyWith(height: 1.8),
                        ),
                        SizedBox(
                          height: landingClamp(
                            context,
                            min: 20,
                            vw: 2.5,
                            max: 32,
                          ),
                        ),
                        LandingBrowserShot(
                          asset: tab.shot,
                          borderColor: Colors.white.withValues(alpha: 0.14),
                          shadow: const [
                            BoxShadow(
                              color: Color(0xA6000000),
                              offset: Offset(0, 46),
                              blurRadius: 90,
                              spreadRadius: -40,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four screen pills, centred over the console.
class _TabRail extends StatelessWidget {
  const _TabRail({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final (index, tab) in LandingContent.dashboardTabs.indexed)
          _TabPill(
            label: tab.label,
            selected: index == selected,
            onTap: () => onSelect(index),
          ),
      ],
    );
  }
}

class _TabPill extends StatefulWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<_TabPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // On the navy band an unselected pill cannot be the design's white chip —
    // it would outshine the selected one. It is a hairline on the band, and
    // the brand fill is what marks the current screen.
    final background = widget.selected
        ? LandingPalette.brand
        : Colors.white.withValues(alpha: _hovered ? 0.14 : 0.07);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: widget.selected
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            widget.label,
            style: LandingType.label(
              12.5,
              color: widget.selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.78),
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
