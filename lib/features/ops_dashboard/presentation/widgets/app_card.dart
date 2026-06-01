import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;

  const AppCard({
    required this.child,
    this.title,
    this.padding = AppSpacing.card,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTokens.cardElevation,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
