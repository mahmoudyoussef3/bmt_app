import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// A floating card anchored above a pin, revealed when the stop is tapped.
Marker buildCalloutMarker(BuildContext context, {required MapRouteStop stop}) {
  return Marker(
    point: stop.coordinate,
    width: 210,
    height: 120,
    // Anchor at the coordinate; the card floats above the pin.
    alignment: Alignment.bottomCenter,
    child: _Callout(name: stop.name),
  );
}

class _Callout extends StatelessWidget {
  const _Callout({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 6),
          child: child,
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: MapStyle.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MapStyle.border(context)),
            boxShadow: MapStyle.shadow(context),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_rounded,
                size: 16,
                color: MapStyle.stop(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name.isEmpty ? 'Route stop' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextThemes.caption(
                    Theme.of(context).colorScheme,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
