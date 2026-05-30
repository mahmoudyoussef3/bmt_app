import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextThemes.headlineStrong(scheme)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(subtitle!, style: AppTextThemes.caption(scheme)),
                ),
            ],
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}
