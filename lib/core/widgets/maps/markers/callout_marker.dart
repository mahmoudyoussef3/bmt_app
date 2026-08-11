import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// A floating card for the tapped stop, parked directly above its pin: it
/// clears the pin's own box (plus the ~14% the pin grows while selected) so it
/// never covers the badge the passenger just tapped.
Marker buildCalloutMarker(
  BuildContext context, {
  required MapRouteStop stop,
  required int index,
  required int count,
}) {
  final prominent = index == 0 || index == count - 1;
  final clearance = MapStyle.pinBox(prominent).height * 1.14 + 6;

  return Marker(
    point: stop.coordinate,
    width: 232,
    height: clearance + 82,
    
    alignment: MapStyle.pinAnchor,
    child: Padding(
      padding: EdgeInsets.only(bottom: clearance),
      child: _Callout(
        name: stop.name,
        role: MapStyle.roleFor(index, count),
        color: MapStyle.colorFor(context, index, count),
        icon: MapStyle.iconFor(index, count),
      ),
    ),
  );
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.name,
    required this.role,
    required this.color,
    required this.icon,
  });

  final String name;
  final String role;
  final Color color;
  final IconData icon;

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
      child: Align(alignment: Alignment.bottomCenter, child: _card(context)),
    );
  }

  Widget _card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MapStyle.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MapStyle.border(context)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: AppTextThemes.caption(scheme).copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
                Text(
                  name.isEmpty ? 'Route stop' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextThemes.caption(
                    scheme,
                  ).copyWith(fontWeight: FontWeight.w800, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
