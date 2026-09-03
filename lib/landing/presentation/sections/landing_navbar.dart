import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_brand.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_scroll_aids.dart';

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
/// A reading-progress rule rides its bottom edge.
///
/// Below 1080px the link rail collapses — the six Arabic labels plus two
/// buttons cannot share a row at tablet width without either wrapping into a
/// second line or truncating. It collapses into a disclosure panel rather
/// than a popup menu: the panel can hold the two account actions as well, so
/// «تسجيل الدخول» stays reachable on a phone instead of disappearing with the
/// rail, and the current section stays marked there as it is in the rail.
class LandingNavbar extends StatefulWidget {
  const LandingNavbar({
    super.key,
    required this.links,
    required this.activeIndex,
    required this.scrolled,
    required this.progress,
    required this.onLogin,
    required this.onGetStarted,
  });

  final List<LandingNavLink> links;

  /// Which section the reader is currently in — the design marks the current
  /// page with ink-coloured, heavier text against the muted rest.
  final int activeIndex;
  final bool scrolled;

  /// How far down the page the reader is, 0 to 1.
  final ValueListenable<double> progress;
  final VoidCallback onLogin;
  final VoidCallback onGetStarted;

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar> {
  bool _menuOpen = false;

  void _run(VoidCallback action) {
    setState(() => _menuOpen = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1080;
    final narrow = width < 620;
    // The rail's return at desktop width leaves nothing for the panel to do.
    final menuOpen = _menuOpen && compact;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: LandingPalette.surface.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: LandingPalette.border)),
        boxShadow: widget.scrolled
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LandingContainer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: widget.scrolled ? 64 : 80,
              child: Row(
                children: [
                  // When the link rail is gone the wordmark takes the free
                  // space itself, pushing the buttons to the far edge. A
                  // Flexible beside a Spacer would split that space with it
                  // and starve the logo tile instead.
                  if (compact)
                    const Expanded(child: _LandingWordmark())
                  else
                    const _LandingWordmark(),
                  if (!compact)
                    Expanded(
                      // Six Arabic labels against a fixed logo and two buttons
                      // is the row most likely to run out of width — a longer
                      // label or a wider face would otherwise overflow rather
                      // than reflow, so the rail scales down before it clips.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < widget.links.length; i++)
                              _NavLinkButton(
                                link: widget.links[i],
                                active: i == widget.activeIndex,
                                onTap: () => _run(widget.links[i].onTap),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (!narrow) ...[
                    LandingButton(
                      label: 'تسجيل الدخول',
                      height: 42,
                      style: LandingButtonStyle.secondary,
                      onPressed: () => _run(widget.onLogin),
                    ),
                    const SizedBox(width: 9),
                  ],
                  LandingButton(
                    label: 'ابدأ مع EWT',
                    height: 42,
                    onPressed: () => _run(widget.onGetStarted),
                  ),
                  if (compact) ...[
                    const SizedBox(width: 9),
                    _NavMenuButton(
                      open: menuOpen,
                      onPressed: () => setState(() => _menuOpen = !_menuOpen),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: menuOpen
                ? _NavMenuPanel(
                    links: widget.links,
                    activeIndex: widget.activeIndex,
                    showAccountActions: narrow,
                    onSelect: _run,
                    onLogin: () => _run(widget.onLogin),
                  )
                : const SizedBox(width: double.infinity),
          ),
          LandingScrollProgress(progress: widget.progress),
        ],
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
  const _NavLinkButton({
    required this.link,
    required this.active,
    required this.onTap,
  });

  final LandingNavLink link;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered || _focused;
    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.link.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? LandingPalette.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              // Keyboard focus needs a mark of its own: the hover ground alone
              // is invisible to someone tabbing through the rail.
              border: Border.all(
                color: _focused ? LandingPalette.brand : Colors.transparent,
              ),
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
      ),
    );
  }
}

/// The tablet/phone toggle for the link panel.
class _NavMenuButton extends StatelessWidget {
  const _NavMenuButton({required this.open, required this.onPressed});

  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: 'أقسام الصفحة',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: open ? LandingPalette.raised : LandingPalette.surface,
              borderRadius: LandingRadii.buttonR,
              border: Border.all(
                color: open
                    ? LandingPalette.brandLine
                    : LandingPalette.borderStrong,
              ),
            ),
            child: Icon(
              open ? Icons.close_rounded : Icons.menu_rounded,
              size: 20,
              color: open ? LandingPalette.brandInk : LandingPalette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The collapsed rail: every section as a full-width row, the current one
/// marked, and — where the header dropped it — the sign-in action.
class _NavMenuPanel extends StatelessWidget {
  const _NavMenuPanel({
    required this.links,
    required this.activeIndex,
    required this.showAccountActions,
    required this.onSelect,
    required this.onLogin,
  });

  final List<LandingNavLink> links;
  final int activeIndex;
  final bool showAccountActions;
  final void Function(VoidCallback action) onSelect;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LandingPalette.surface,
        border: Border(top: BorderSide(color: LandingPalette.borderSoft)),
      ),
      child: ConstrainedBox(
        // The panel pushes the page down rather than floating over it, so on
        // a short viewport it must give the content back its room.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: SingleChildScrollView(
          child: LandingContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < links.length; i++)
                    _NavMenuRow(
                      label: links[i].label,
                      active: i == activeIndex,
                      onTap: () => onSelect(links[i].onTap),
                    ),
                  if (showAccountActions) ...[
                    const SizedBox(height: 10),
                    LandingButton(
                      label: 'تسجيل الدخول',
                      height: 46,
                      style: LandingButtonStyle.secondary,
                      expand: true,
                      onPressed: onLogin,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavMenuRow extends StatelessWidget {
  const _NavMenuRow({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: active ? LandingPalette.brandTint : Colors.transparent,
              borderRadius: LandingRadii.buttonR,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: LandingType.label(
                      14,
                      color: active
                          ? LandingPalette.brandInk
                          : LandingPalette.ink,
                      weight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  size: 19,
                  color: active
                      ? LandingPalette.brandInk
                      : LandingPalette.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
