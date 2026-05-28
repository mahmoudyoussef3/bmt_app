import 'package:flutter/material.dart';

class MapPlaceholder extends StatelessWidget {
  final double height;
  const MapPlaceholder({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withAlpha(31),
            Theme.of(context).colorScheme.secondary.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.map,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
        ),
      ),
    );
  }
}
