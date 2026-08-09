import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'coming_soon_badge.dart';

/// One alternative sign-in method, in the two densities the app needs.
///
/// The visual language is fixed here so Google, Apple and phone can never drift
/// apart: same height, same pill radius as [ClientButton] so the row sits
/// naturally under the primary call to action, and a glyph that keeps its own
/// colour (Google's mark is not ours to tint).
///
/// ## The pending look
///
/// A method with no provider behind it is drawn as a *quieter version of the
/// real thing*, not as a dead control: the subtle surface fill instead of the
/// raised one, the label one step down the text ramp, the glyph at reduced
/// opacity, and a [ComingSoonBadge] where the chevron would be. Nothing is
/// greyed to the point of looking faulty — the rider should read "this exists,
/// just not yet", which is exactly true.
///
/// It carries no gesture detector at all in that state, so there is nothing to
/// tap and no dead-end sheet to land in. An earlier build did open a "coming
/// soon" bottom sheet from these buttons and it was removed for being a dead
/// end on the very first tap a new rider makes; the affordance now says so
/// before the tap instead of after it.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.onPressed,
    this.compactLabel,
    this.isAvailable = true,
    this.isLoading = false,
    this.compact = false,
  });

  /// Full label ("Continue with Google"). In [compact] mode it is also used as
  /// the accessibility label while [compactLabel] is what is drawn.
  final String label;

  /// Short label for the compact tile ("Google", "Phone"). Falls back to
  /// [label] when a method has no shorter name worth giving it.
  final String? compactLabel;

  final Widget glyph;

  /// `null` disables the button. Providers that are not wired up pass `null`
  /// *and* `isAvailable: false` — the first makes it inert, the second explains
  /// why.
  final VoidCallback? onPressed;

  /// Whether the provider behind this method exists in this build. Drives the
  /// "coming soon" treatment; unrelated to [onPressed] being momentarily null
  /// during a submit.
  final bool isAvailable;

  final bool isLoading;

  /// Tile form for the welcome screen, where three full-width rows under the
  /// hero would push the primary action off a small phone.
  final bool compact;

  bool get _enabled => isAvailable && onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = compact ? _buildTile(context) : _buildRow(context);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: isAvailable ? label : '$label — ${l10n.auth_comingSoon}',
      child: ExcludeSemantics(
        child: _enabled
            ? PressableScale(onTap: onPressed, scale: 0.97, child: body)
            : body,
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) => BoxDecoration(
    color: isAvailable
        ? ClientColors.surfaceFor(context)
        : ClientColors.surfaceSubtleFor(context),
    borderRadius: BorderRadius.circular(ClientRadius.pill),
    border: Border.all(color: ClientColors.borderFor(context)),
  );

  /// A glyph that is dimmed, not recoloured, when the method is pending —
  /// Google's mark must keep its own colours whatever state the button is in.
  Widget _glyph() => isAvailable ? glyph : Opacity(opacity: 0.55, child: glyph);

  Widget _buildRow(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 14, 12),
      decoration: _decoration(context),
      child: Row(
        children: [
          SizedBox(width: 22, child: Center(child: _glyph())),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelLarge(context).copyWith(
                color: isAvailable
                    ? ClientColors.textPrimaryFor(context)
                    : ClientColors.textSecondaryFor(context),
              ),
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          _trailing(context),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.center,
      decoration: _decoration(context),
      child: isLoading
          ? _spinner(context)
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glyph(),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    compactLabel ?? label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: isAvailable
                          ? ClientColors.textPrimaryFor(context)
                          : ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _trailing(BuildContext context) {
    if (isLoading) return _spinner(context);
    if (!isAvailable) return const ComingSoonBadge();
    return const SizedBox(width: 8);
  }

  Widget _spinner(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(
        ClientColors.primaryFor(context),
      ),
    ),
  );
}
