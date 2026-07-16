import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

/// The common shell for every titled block on the profile screen: an accented
/// icon, a heading, then the block's own content.
class DriverProfileSectionCard extends StatelessWidget {
  const DriverProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: CaptainColors.primary.withValues(alpha: 0.1),
                  borderRadius: CaptainDesignTokens.br12,
                ),
                child: Icon(icon, size: 18, color: CaptainColors.primary),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Expanded(
                child: Text(
                  title,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          child,
        ],
      ),
    );
  }
}
