import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

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
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(title: title, onBack: onBack),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            ClientSpacing.md,
            ClientSpacing.sm,
            ClientSpacing.md,
            ClientSpacing.xl,
          ),
          child: child,
        ),
      ),
    );
  }
}
