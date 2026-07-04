import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class BookingStepIntro extends StatelessWidget {
  const BookingStepIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: ClientColors.primaryGradientFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            boxShadow: ClientElevation.sm(context),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ClientTypography.headingSmall(context)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class BookingSurfaceCard extends StatelessWidget {
  const BookingSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? ClientColors.primaryFor(context);
    return AnimatedContainer(
      duration: ClientMotion.base,
      curve: ClientMotion.curve,
      padding: padding,
      decoration: BoxDecoration(
        color: selected
            ? accent.withAlpha(
                Theme.of(context).brightness == Brightness.dark ? 28 : 14,
              )
            : ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(
          color: selected ? accent : ClientColors.borderFor(context),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? ClientElevation.sm(context) : null,
      ),
      child: child,
    );
  }
}

class BookingBottomAction extends StatelessWidget {
  const BookingBottomAction({super.key, required this.child, this.summary});

  final Widget child;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        boxShadow: ClientElevation.sm(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summary != null) ...[summary!, const SizedBox(height: 10)],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class BookingCountPill extends StatelessWidget {
  const BookingCountPill({
    super.key,
    required this.label,
    this.color = ClientColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
