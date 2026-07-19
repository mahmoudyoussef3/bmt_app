import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_details_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_gallery_background.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Collapsing gallery header for the vehicle details screen.
class VehicleGalleryAppBar extends StatelessWidget {
  const VehicleGalleryAppBar({
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
    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      stretch: true,
      title: Text(context.l10n.booking_vehicleDetails),
      actions: [
        IconButton(
          tooltip: context.l10n.tracking_refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<VehicleDetailsCubit>().load(vehicle.id),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: VehicleGalleryBackground(
          vehicle: vehicle,
          galleryController: galleryController,
          galleryIndex: galleryIndex,
          onPageChanged: onPageChanged,
        ),
      ),
    );
  }
}
