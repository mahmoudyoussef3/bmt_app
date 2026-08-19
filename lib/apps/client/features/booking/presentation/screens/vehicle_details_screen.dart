import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_details_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_details_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_bottom_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_details_body.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_details_states.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_gallery_app_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/booking_query_summary.dart';

/// Full vehicle profile for informed booking decisions.
class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
      builder: (context, state) {
        if (state is VehicleDetailsLoading) return const VehicleLoadingView();
        if (state is VehicleDetailsError) {
          return VehicleErrorView(message: state.message);
        }
        final vehicle = state is VehicleDetailsLoaded ? state.vehicle : null;
        if (vehicle == null) return const VehicleEmptyView();

        final query = bookingQueryFromContext(context);
        return Scaffold(
          extendBody: true,
          body: CustomScrollView(
            slivers: [
              VehicleGalleryAppBar(
                vehicle: vehicle,
                galleryController: _galleryController,
                galleryIndex: _galleryIndex,
                onPageChanged: (index) => setState(() => _galleryIndex = index),
              ),
              SliverToBoxAdapter(
                child: VehicleDetailsBody(
                  vehicle: vehicle,
                  routeSummary: query.isComplete
                      ? bookingQuerySummary(query, context)
                      : null,
                ),
              ),
            ],
          ),
          bottomNavigationBar: VehicleBottomBar(vehicle: vehicle),
        );
      },
    );
  }
}
