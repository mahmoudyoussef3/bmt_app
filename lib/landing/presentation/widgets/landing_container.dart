import 'package:flutter/material.dart';

/// Centered, max-width content wrapper for a marketing page section.
///
/// The app's [AppLayout.maxContentWidth] tops out at 720 — right for a phone
/// or tablet app screen, too narrow for a desktop landing page — so this
/// keeps its own wider ladder instead of reusing that constant.
class LandingContainer extends StatelessWidget {
  const LandingContainer({
    super.key,
    required this.child,
    this.maxWidth = 1160,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 720;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 720 && width < 1080;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1080;

  @override
  Widget build(BuildContext context) {
    final horizontal = isMobile(context)
        ? 20.0
        : isTablet(context)
        ? 32.0
        : 48.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

/// Vertical rhythm for stacked sections — every section picks a size instead
/// of inlining its own [SizedBox], so the page has one consistent beat.
class LandingSectionPadding extends StatelessWidget {
  const LandingSectionPadding({super.key, required this.child, this.tight = false});

  final Widget child;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final mobile = LandingContainer.isMobile(context);
    final vertical = tight
        ? (mobile ? 40.0 : 56.0)
        : (mobile ? 56.0 : 88.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: child,
    );
  }
}
