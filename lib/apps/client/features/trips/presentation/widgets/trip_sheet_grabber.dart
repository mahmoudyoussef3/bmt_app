import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The drag handle shared by the trips modal sheets (review, cancellation).
class TripSheetGrabber extends StatelessWidget {
  const TripSheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ClientColors.borderFor(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
