import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// The one place an auth screen reports a failure that isn't a field's fault —
/// an unregistered number, a rate limit, a dead connection.
///
/// Drawn as a card with a danger rail down its leading edge rather than as a
/// slab of red: a field error and a screen error are different things, and the
/// screen-level one has to stay readable next to a form that may already be
/// showing red under a field. It occupies no height at all when there is no
/// message, so the layout above it does not shift when one arrives.
class CaptainAuthErrorBanner extends StatelessWidget {
  const CaptainAuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final danger = CaptainColors.dangerFor(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Container(
                key: const ValueKey('captain-auth-error'),
                margin: const EdgeInsetsDirectional.only(
                  bottom: CaptainDesignTokens.s16,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: CaptainColors.surfaceFor(context),
                  borderRadius: CaptainDesignTokens.br16,
                  border: Border.all(color: danger.withValues(alpha: 0.35)),
                ),
                // The rail is positioned rather than stretched down a Row: an
                // `IntrinsicHeight` around an `Expanded` `Text` measures the
                // message at the wrong width and settles one line short, which
                // truncates exactly the errors long enough to need two lines.
                // Here the padded content sizes the stack and the rail follows.
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        CaptainDesignTokens.s16,
                        CaptainDesignTokens.s12,
                        CaptainDesignTokens.s8,
                        CaptainDesignTokens.s12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: danger,
                            size: 20,
                          ),
                          const SizedBox(width: CaptainDesignTokens.s12),
                          Expanded(
                            child: Text(
                              text,
                              style: CaptainTypography.bodySmall(context)
                                  .copyWith(
                                    color: CaptainColors.textPrimaryFor(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                          if (onDismiss != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: CaptainDesignTokens.s4,
                              ),
                              child: InkResponse(
                                onTap: onDismiss,
                                radius: 20,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: CaptainColors.textSecondaryFor(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: ColoredBox(color: danger),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
