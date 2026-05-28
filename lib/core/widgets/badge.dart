import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const AppBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.tertiary.withAlpha(31);
    final fg = Theme.of(context).colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
