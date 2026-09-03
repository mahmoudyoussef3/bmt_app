import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';

/// The 2px reading-progress rule that sits on the header's bottom hairline.
///
/// Eighteen bands is a long document, and the header is the only fixed thing
/// on the page — putting the progress there answers "how much is left?"
/// without adding another element to the layout.
class LandingScrollProgress extends StatelessWidget {
  const LandingScrollProgress({super.key, required this.progress});

  /// 0 at the top of the page, 1 at the bottom.
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, value, _) => SizedBox(
        height: 2,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: value.clamp(0.0, 1.0),
          // A childless DecoratedBox takes the smallest size its constraints
          // allow, so without a height factor to tighten them the rule paints
          // 2px tall and zero pixels high.
          heightFactor: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [LandingPalette.brand, LandingPalette.brandDeep],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The return-to-top control, shown once the reader is a screen past the hero.
///
/// On a page this tall the only way back to the header's nav was to scroll
/// the whole way, which on a phone is the difference between the reader
/// re-reading the page and the reader leaving it.
class LandingBackToTop extends StatelessWidget {
  const LandingBackToTop({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final ValueListenable<bool> visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, shown, child) => IgnorePointer(
        ignoring: !shown,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          offset: shown ? Offset.zero : const Offset(0, 0.6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 240),
            opacity: shown ? 1 : 0,
            child: child,
          ),
        ),
      ),
      child: _BackToTopButton(onPressed: onPressed),
    );
  }
}

class _BackToTopButton extends StatefulWidget {
  const _BackToTopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<_BackToTopButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'العودة لأعلى الصفحة',
      child: Tooltip(
        message: 'العودة لأعلى الصفحة',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 46,
              height: 46,
              alignment: Alignment.center,
              // A paper-white chip, not a navy one: the control floats over
              // every band the page has, and the last of them — the footer —
              // is navy, where a navy button would simply vanish.
              decoration: BoxDecoration(
                color: _hovered
                    ? LandingPalette.brandTint
                    : LandingPalette.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hovered
                      ? LandingPalette.brandLine
                      : LandingPalette.borderStrong,
                ),
                boxShadow: LandingPalette.liftedShadow,
              ),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24,
                color: _hovered ? LandingPalette.brandInk : LandingPalette.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
