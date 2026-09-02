import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_brand.dart';
import '../widgets/landing_layout.dart';

/// One entry in the header's section nav.
class LandingNavLink {
  const LandingNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// The sticky page header.
///
/// It shrinks from 80px to 64px once the page has scrolled past 24px and
/// gains a shadow at the same moment — the design's `scrolled` state, which
/// is what keeps the header from sitting as a heavy slab over the content.
/// Below 1080px the link rail collapses into a menu button, because the six
/// Arabic labels plus two buttons cannot share a row at tablet width without
/// either wrapping into a second line or truncating.
class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    super.key,
    required this.links,
    required this.activeIndex,
    required this.scrolled,
    required this.onLogin,
    required this.onGetStarted,
  });

  final List<LandingNavLink> links;

  /// Which section the reader is currently in — the design marks the current
  /// page with ink-coloured, heavier text against the muted rest.
  final int activeIndex;
  final bool scrolled;
  final VoidCallback onLogin;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1080;
    final narrow = width < 620;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: LandingPalette.surface.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: LandingPalette.border)),
        boxShadow: scrolled
            ? const [
                BoxShadow(
                  color: Color(0x8C0B1B34),
                  offset: Offset(0, 10),
                  blurRadius: 28,
                  spreadRadius: -22,
                ),
              ]
            : null,
      ),
      child: LandingContainer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: scrolled ? 64 : 80,
          child: Row(
            children: [
              // When the link rail is gone the wordmark takes the free
              // space itself, pushing the buttons to the far edge. A Flexible
              // beside a Spacer would split that space with it and starve the
              // logo tile instead.
              if (compact)
                const Expanded(child: _LandingWordmark())
              else
                const _LandingWordmark(),
              if (!compact) ...[
                Expanded(
                  // Six Arabic labels against a fixed logo and two buttons is
                  // the row most likely to run out of width — a longer label
                  // or a wider face would otherwise overflow rather than
                  // reflow, so the rail scales down before it ever clips.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < links.length; i++)
                          _NavLinkButton(
                            link: links[i],
                            active: i == activeIndex,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!narrow) ...[
                LandingButton(
                  label: 'تسجيل الدخول',
                  height: 42,
                  style: LandingButtonStyle.secondary,
                  onPressed: onLogin,
                ),
                const SizedBox(width: 9),
              ],
              LandingButton(
                label: 'ابدأ مع EWT',
                height: 42,
                onPressed: onGetStarted,
              ),
              if (compact) ...[
                const SizedBox(width: 9),
                _NavMenuButton(links: links),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand mark: the shipping app icon plus the two-line wordmark.
class _LandingWordmark extends StatelessWidget {
  const _LandingWordmark();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return LandingBrandMark(showWordmark: !narrow);
  }
}

class _NavLinkButton extends StatefulWidget {
  const _NavLinkButton({required this.link, required this.active});

  final LandingNavLink link;
  final bool active;

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.link.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? LandingPalette.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.link.label,
            style: LandingType.label(
              13.5,
              color: highlighted ? LandingPalette.ink : LandingPalette.muted,
              weight: widget.active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The tablet/phone stand-in for the link rail.
class _NavMenuButton extends StatelessWidget {
  const _NavMenuButton({required this.links});

  final List<LandingNavLink> links;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'أقسام الصفحة',
      color: LandingPalette.surface,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: LandingRadii.buttonR,
        side: const BorderSide(color: LandingPalette.border),
      ),
      onSelected: (index) => links[index].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < links.length; i++)
          PopupMenuItem(
            value: i,
            height: 42,
            child: Text(
              links[i].label,
              style: LandingType.label(13.5, color: LandingPalette.ink),
            ),
          ),
      ],
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: LandingRadii.buttonR,
          border: Border.all(color: LandingPalette.borderStrong),
        ),
        child: const Icon(
          Icons.menu_rounded,
          size: 20,
          color: LandingPalette.ink,
        ),
      ),
    );
  }
}
