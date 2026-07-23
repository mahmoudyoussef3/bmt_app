import 'package:flutter/material.dart';

/// A soft, tinted icon badge reused across Trip Details' cards.
class TripSoftIcon extends StatelessWidget {
  const TripSoftIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

