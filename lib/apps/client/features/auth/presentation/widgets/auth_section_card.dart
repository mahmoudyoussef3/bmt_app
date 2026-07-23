import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// A group of auth fields on the standard [ClientCard] surface, with an
/// optional titled header. It used to hand-roll its own white box, radius and
/// divider, which drifted from the cards on every other client screen.
class AuthSectionCard extends StatelessWidget {
  const AuthSectionCard({
    super.key,
    required this.children,
    this.title,
    this.icon,
  });

  final List<Widget> children;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final String heading) ...[
            _SectionHeader(title: heading, icon: icon),
            const SizedBox(height: ClientSpacing.md),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon case final IconData glyph) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ClientColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(ClientRadius.sm),
            ),
            child: Icon(
              glyph,
              size: 18,
              color: ClientColors.primaryFor(context),
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
        ],
        Expanded(
          child: Text(title, style: ClientTypography.headingSmall(context)),
        ),
      ],
    );
  }
}
