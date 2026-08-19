import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../cubit/captain_trip_map_cubit.dart';
import '../cubit/captain_trip_map_state.dart';
import '../widgets/captain_gps_health_pill.dart';
import '../widgets/map/captain_trip_map.dart';
import '../widgets/panel/captain_next_pickup_sheet.dart';

class CaptainTripMapPage extends StatelessWidget {
  const CaptainTripMapPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CaptainTripMapCubit>(
      create: (_) => captainGetIt<CaptainTripMapCubit>()..start(trip),
      child: _CaptainTripMapView(trip: trip),
    );
  }
}

class _CaptainTripMapView extends StatelessWidget {
  const _CaptainTripMapView({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelMaxHeight = size.height * 0.52;
    final bottomInset = size.height * 0.4;
    final route = _routePoints(trip);

    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: BlocConsumer<CaptainTripMapCubit, CaptainTripMapState>(
        listenWhen: (previous, current) =>
            previous.actionError != current.actionError &&
            current.actionError != null,
        listener: (context, state) {
          AppSnackbar.error(context, state.actionError!);
          context.read<CaptainTripMapCubit>().clearActionError();
        },
        builder: (context, state) {
          final cubit = context.read<CaptainTripMapCubit>();
          return Stack(
            children: [
              Positioned.fill(
                child: CaptainTripMap(
                  route: route,
                  fix: state.fix,
                  progress: state.progress,
                  activePickup: _activePickupPoint(state),
                  bottomInset: bottomInset,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(title: trip.route),
                      const SizedBox(height: CaptainDesignTokens.s8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CaptainGpsHealthPill(
                          health: state.gpsHealth,
                          message: state.gpsMessage,
                          onRetry: cubit.retryLocation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: panelMaxHeight),
                  child: CaptainNextPickupSheet(
                    state: state,
                    onConfirm: cubit.confirmBoarded,
                    onAbsent: cubit.markAbsent,
                    onReset: cubit.markPending,
                    onArrived: cubit.markArrivedAtActivePickup,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<LatLng> _routePoints(AssignedTrip trip) => [
    for (final stop in trip.stops)
      if (stop.hasCoordinates) LatLng(stop.latitude!, stop.longitude!),
  ];

  LatLng? _activePickupPoint(CaptainTripMapState state) {
    final active = state.pickup.active;
    if (active == null || !active.hasCoordinates) return null;
    return LatLng(active.latitude!, active.longitude!);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.arrow_back_rounded,
          onTap: context.closeScreen,
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s16,
              vertical: CaptainDesignTokens.s12,
            ),
            decoration: BoxDecoration(
              color: CaptainColors.surfaceFor(context),
              borderRadius: CaptainDesignTokens.brPill,
              boxShadow: CaptainDesignTokens.softShadow(context),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 18,
                  color: CaptainColors.primary,
                ),
                const SizedBox(width: CaptainDesignTokens.s8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.titleSmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Material(
        color: CaptainColors.surfaceFor(context),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: CaptainColors.textPrimaryFor(context)),
          ),
        ),
      ),
    );
  }
}
