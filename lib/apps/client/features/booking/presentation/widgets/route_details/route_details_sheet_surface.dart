import 'package:flutter/material.dart';

/// The rounded, shadowed sheet surface wrapping Route Details' scrollable
/// content inside the [DraggableScrollableSheet].
class RouteDetailsSheetSurface extends StatelessWidget {
  const RouteDetailsSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}
