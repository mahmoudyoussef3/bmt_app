import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The two-dot vertical connector used by [RouteEndpointLine] to visualize
/// an origin-to-destination path.
class RouteLine extends StatelessWidget {
  const RouteLine({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 72,
      child: Column(
        children: [
          RouteLineDot(
            color: active
                ? ClientColors.primaryFor(context)
                : ClientColors.textTertiaryFor(context),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                color: ClientColors.borderFor(context),
              ),
            ),
          ),
          RouteLineDot(
            color: active ? ClientColors.journeyAmber : ClientColors.border,
          ),
        ],
      ),
    );
  }
}

class RouteLineDot extends StatelessWidget {
  const RouteLineDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
