import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The phone layout's draggable sheet over the map.
///
/// It opens at a height that shows the status, the hero ETA and the top of the
/// rider's booking without a drag — the three things somebody who just opened
/// tracking came to see — and pulls up to the full stop list from there.
class TrackingSheetScaffold extends StatelessWidget {
  const TrackingSheetScaffold({
    super.key,
    required this.controller,
    required this.builder,
  });

  final DraggableScrollableController controller;
  final Widget Function(ScrollController scrollController) builder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.42,
      minChildSize: 0.22,
      maxChildSize: 0.9,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(24),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: builder(scrollController),
      ),
    );
  }
}
