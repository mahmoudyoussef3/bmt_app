import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';

/// The gallery image, scrim and caption behind the vehicle details app bar.
class VehicleGalleryBackground extends StatelessWidget {
  const VehicleGalleryBackground({
    super.key,
    required this.vehicle,
    required this.galleryController,
    required this.galleryIndex,
    required this.onPageChanged,
  });

  final VehicleDetailData vehicle;
  final PageController galleryController;
  final int galleryIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        VehicleImageStrip(
          labels: vehicle.imageLabels,
          height: 310,
          pageController: galleryController,
          onPageChanged: onPageChanged,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(95),
                Colors.black.withAlpha(10),
                Colors.black.withAlpha(160),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingLarge(
                  context,
                ).copyWith(color: ClientColors.textInverse, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                vehicle.model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(context).copyWith(
                  color: ClientColors.textInverse.withAlpha(220),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              VehicleImageDots(
                count: vehicle.imageLabels.length,
                index: galleryIndex,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
