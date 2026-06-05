import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.002 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Card(
          elevation: _hovered
              ? AppTokens.cardElevation
              : AppTokens.surfaceElevation,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
