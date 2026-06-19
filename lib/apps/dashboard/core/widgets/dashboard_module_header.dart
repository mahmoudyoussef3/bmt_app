import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Unified page header used by every dashboard module (Trips, Fleet, Routes…).
///
/// A primary-tinted banner with an icon, title, subtitle and trailing
/// [actions], plus an optional [child] rendered below the banner inside the
/// same card (e.g. a KPI strip + filters). Having one widget — instead of each
/// screen hand-rolling its own banner — is what makes the modules feel like a
/// single product.
class DashboardModuleHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? child;

  const DashboardModuleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(14),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
              border: Border(
                bottom: BorderSide(color: scheme.outline.withAlpha(30)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleBlock = _TitleBlock(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                );
                if (actions.isEmpty) return titleBlock;

                final actionBar = Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: actions,
                );
                if (constraints.maxWidth < 780) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: AppSpacing.medium),
                      actionBar,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: AppSpacing.medium),
                    actionBar,
                  ],
                );
              },
            ),
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TitleBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
