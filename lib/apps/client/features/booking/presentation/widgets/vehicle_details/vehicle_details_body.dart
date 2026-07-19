import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_comfort_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_detail_section.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_driver_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_pricing_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_quick_stats.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_route_summary_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Scrolling content of the vehicle details screen: stats, comfort, driver,
/// pricing and (optionally) the searched-route summary.
class VehicleDetailsBody extends StatelessWidget {
  const VehicleDetailsBody({
    super.key,
    required this.vehicle,
    required this.routeSummary,
  });

  final VehicleDetailData vehicle;
  final String? routeSummary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VehicleQuickStats(vehicle: vehicle),
          const SizedBox(height: 20),
          VehicleDetailSection(
            title: l10n.booking_comfortAndAmenities,
            subtitle: l10n.booking_comfortDesc,
            icon: Icons.airline_seat_recline_extra_rounded,
            child: VehicleComfortCard(vehicle: vehicle),
          ),
          const SizedBox(height: 20),
          VehicleDetailSection(
            title: l10n.booking_driver,
            subtitle: l10n.booking_driverDesc,
            icon: Icons.person_pin_circle_rounded,
            child: VehicleDriverCard(vehicle: vehicle),
          ),
          const SizedBox(height: 20),
          VehicleDetailSection(
            title: l10n.booking_priceAndAvailability,
            subtitle: l10n.booking_priceDesc,
            icon: Icons.payments_rounded,
            child: VehiclePricingCard(vehicle: vehicle),
          ),
          if (routeSummary != null) ...[
            const SizedBox(height: 14),
            VehicleRouteSummaryCard(summary: routeSummary!),
          ],
        ],
      ),
    );
  }
}
