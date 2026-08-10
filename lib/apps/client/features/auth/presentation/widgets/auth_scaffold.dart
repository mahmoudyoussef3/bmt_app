import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The shared chrome of every auth screen.
///
/// Auth used to draw its own toolbar and a gradient wash behind a display-sized
/// title, which is why signing in read as a different product from the app
/// behind it. It now sits on the same [ClientAppBar] + subtle canvas every other
/// client screen uses, and owns only what a keyboard-heavy form needs: a scroll
/// view that dismisses the keyboard on drag and leaves room under the last
/// control.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;

  /// Overrides the back arrow; the forgot-password panes use it to unwind one
  /// pane at a time instead of leaving the flow.
  final VoidCallback? onBack;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool showsBack = onBack != null || (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ClientColors.backgroundFor(context),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ClientColors.heroGradientFor(context),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        if (showsBack)
                          IconButton(
                            icon: const DirectionalIcon(Icons.arrow_back_rounded),
                            color: ClientColors.textInverse,
                            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        ClientSpacing.md,
                        0,
                        ClientSpacing.md,
                        ClientSpacing.xl,
                      ),
                      child: child,
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
