import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.height = 12,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withAlpha(15),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}
