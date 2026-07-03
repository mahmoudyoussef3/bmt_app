import 'package:flutter/material.dart';
import '../theme/captain_spacing.dart';

class CaptainCard extends StatelessWidget {
  const CaptainCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CaptainSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: CaptainRadius.rXl,
        border: Border.all(
          color: borderColor ?? scheme.outline.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: CaptainRadius.rXl,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
