import 'package:flutter/material.dart';

import '../../domain/entities/driver.dart';

class DriverAvatar extends StatelessWidget {
  final Driver driver;
  final double radius;

  const DriverAvatar({required this.driver, this.radius = 22, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        driver.avatarInitials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
