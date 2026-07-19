import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The bottom action bar that stays pinned below a scrolling pane.
class SubscriptionStickyCta extends StatelessWidget {
  const SubscriptionStickyCta({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: ClientButton(label: label, expand: true, onPressed: onPressed),
      ),
    );
  }
}
