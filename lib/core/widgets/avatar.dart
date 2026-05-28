import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? initials;
  final double radius;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.initials,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ??
          Theme.of(context).colorScheme.secondary.withAlpha(46),
      child: Text(
        initials ?? '',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
