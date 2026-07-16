import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Shared shell for the captain auth screens (login + request access).
///
/// Provides the ambient brand glow, an optional back affordance, and a
/// vertically-centered, width-constrained scroll area so the keyboard never
/// clips the form. Inherits the app's ambient RTL — the phone number field
/// (`CaptainAuthField`) scopes its own LTR to just the digits it displays, so
/// nothing here needs to force a direction on the rest of the Arabic screen.
class CaptainAuthScaffold extends StatelessWidget {
  const CaptainAuthScaffold({
    super.key,
    required this.child,
    this.showBack = false,
  });

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: Stack(
        children: [
          PositionedDirectional(
            top: -120,
            end: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [scheme.primary.withAlpha(36), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (showBack)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const DirectionalIcon(
                          Icons.arrow_back_ios_new_rounded,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s16,
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s32,
                    ),
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
    );
  }
}
