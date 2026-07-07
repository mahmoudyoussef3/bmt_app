import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const AppBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.primary;
    final bg = fg.withAlpha(24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withAlpha(90)),
      ),
      child: Text(
        text,
        style: AppTextThemes.badgeText(scheme).copyWith(color: fg),
      ),
    );
  }
}
