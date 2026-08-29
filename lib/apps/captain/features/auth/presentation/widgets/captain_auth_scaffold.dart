import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import 'captain_auth_hero.dart';

/// The chrome every captain auth screen sits in.
///
/// Two layouts, chosen by whether a [hero] was given:
///
/// * **With a hero** the page opens on a brand band — a full-bleed header in
///   the brand fill, rounded off at the bottom, carrying the mark and the
///   headings — and the form sits on the canvas below it. This is the app's
///   front door and the only place in the captain app that still paints a
///   coloured header.
/// * **Without one** it is the quiet canvas the rest of the app uses, with a
///   single brand halo top-end. The join flow's pending / approved / rejected
///   panes take this shape: they are outcomes, not entrances.
///
/// It also owns the two things a keyboard-heavy form needs and no screen should
/// have to remember: tapping the page dismisses the keyboard, and so does
/// dragging the scroll view.
class CaptainAuthScaffold extends StatelessWidget {
  const CaptainAuthScaffold({
    super.key,
    required this.child,
    this.hero,
    this.showBack = false,
    this.onBack,
  });

  final Widget child;

  /// Drawn on the brand band. Normally a [CaptainAuthHero].
  final Widget? hero;

  final bool showBack;

  /// Overrides what the back control does — the join flow unwinds its own state
  /// rather than popping a route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final hasHero = hero != null;

    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (!hasHero) const _CanvasHalo(),
            SafeArea(
              top: !hasHero,
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (hasHero)
                    SliverToBoxAdapter(
                      child: _HeroBand(
                        showBack: showBack,
                        onBack: onBack,
                        child: hero!,
                      ),
                    )
                  else if (showBack)
                    SliverToBoxAdapter(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CaptainDesignTokens.s16,
                            vertical: CaptainDesignTokens.s8,
                          ),
                          child: _BackControl(onBack: onBack, onBand: false),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CaptainDesignTokens.s20,
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s20,
                      CaptainDesignTokens.s32,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The brand header the form hangs off. Full-bleed to the status bar, so the
/// band reads as the top of the screen rather than as a card that happens to be
/// blue.
class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.child,
    required this.showBack,
    required this.onBack,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final compact = CaptainAuthHero.compactFor(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        CaptainDesignTokens.s20,
        topInset +
            (showBack ? CaptainDesignTokens.s12 : CaptainDesignTokens.s24),
        CaptainDesignTokens.s20,
        compact ? CaptainDesignTokens.s20 : CaptainDesignTokens.s32,
      ),
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: const BorderRadiusDirectional.only(
          bottomStart: CaptainDesignTokens.r32,
          bottomEnd: CaptainDesignTokens.r32,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only reserved when there is something to put in it: on the login
          // screen — the one screen with no way back — a 40pt empty row is
          // 40pt the form does not get on a short phone.
          if (showBack)
            SizedBox(
              height: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _BackControl(onBack: onBack, onBand: true),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 40×40 tile rather than a bare [IconButton]: on the band it needs a surface
/// of its own to stay visible, and off it, it matches the bordered square the
/// rest of the captain app uses for secondary chrome.
class _BackControl extends StatelessWidget {
  const _BackControl({required this.onBack, required this.onBand});

  final VoidCallback? onBack;
  final bool onBand;

  @override
  Widget build(BuildContext context) {
    final ink = onBand
        ? ClientColors.onHeroFor(context)
        : CaptainColors.textPrimaryFor(context);

    return Material(
      color: onBand
          ? Colors.white.withValues(alpha: 0.16)
          : CaptainColors.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: CaptainDesignTokens.br12,
        side: BorderSide(
          color: onBand
              ? Colors.white.withValues(alpha: 0.22)
              : CaptainColors.borderFor(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: DirectionalIcon(
              Icons.arrow_back_rounded,
              size: 20,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiet page's one piece of decoration.
class _CanvasHalo extends StatelessWidget {
  const _CanvasHalo();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: -120,
      end: -60,
      child: IgnorePointer(
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                CaptainColors.primaryInkFor(context).withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
