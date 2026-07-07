import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The numbered dot + connector column for one row in
/// [RouteOverviewStopTimeline].
class OverviewStopDot extends StatelessWidget {
  const OverviewStopDot({
    super.key,
    required this.order,
    required this.isFirst,
    required this.isLast,
  });

  final int order;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isEndpoint = isFirst || isLast;

    return SizedBox(
      width: 32,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst
                  ? ClientColors.primary
                  : isLast
                  ? ClientColors.journeyGreen
                  : ClientColors.primaryLight,
              border: Border.all(
                color: isEndpoint ? Colors.transparent : ClientColors.primary,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '$order',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isEndpoint ? Colors.white : ClientColors.primary,
                ),
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 28,
              color: ClientColors.primary.withAlpha(30),
            ),
        ],
      ),
    );
  }
}
