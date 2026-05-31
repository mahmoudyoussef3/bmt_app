import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;

  const AppCard({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
