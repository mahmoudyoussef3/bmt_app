import 'package:flutter/material.dart';

class AppSeparator extends StatelessWidget {
  final double thickness;
  final EdgeInsetsGeometry margin;

  const AppSeparator({
    super.key,
    this.thickness = 1,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Theme.of(context).dividerColor.withAlpha(60),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
