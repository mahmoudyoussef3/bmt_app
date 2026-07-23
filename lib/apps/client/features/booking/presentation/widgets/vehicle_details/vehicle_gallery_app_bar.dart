import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
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
    return ClientSliverAppBar(
      title: context.l10n.booking_vehicleDetails,
      expandedHeight: 310,
      stretch: true,
      background: VehicleGalleryBackground(
        vehicle: vehicle,
        galleryController: galleryController,
        galleryIndex: galleryIndex,
        onPageChanged: onPageChanged,
      ),
      actions: [
        IconButton(
          tooltip: context.l10n.tracking_refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<VehicleDetailsCubit>().load(vehicle.id),
        ),
      ],
    );
  }
}
