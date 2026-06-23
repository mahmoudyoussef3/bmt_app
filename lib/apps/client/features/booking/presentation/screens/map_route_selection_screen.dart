import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/google_style_map_view.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Map-based route overview.
class MapRouteSelectionScreen extends StatefulWidget {
  const MapRouteSelectionScreen({super.key});

  @override
  State<MapRouteSelectionScreen> createState() =>
      _MapRouteSelectionScreenState();
}

class _MapRouteSelectionScreenState extends State<MapRouteSelectionScreen> {
  late BookingSearchQuery _query;
  MapPinOption? _pickup;
  MapPinOption? _destination;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
    if (_didLoad) return;
    _didLoad = true;
    context.read<BookingCubit>().loadMapPins();
  }

  void _syncPins(List<MapPinOption> pickupPins, List<MapPinOption> destPins) {
    if (_pickup == null && pickupPins.isNotEmpty) {
      _pickup = _query.pickup.isEmpty
          ? pickupPins.first
          : pickupPins.firstWhere(
              (pin) => pin.label == _query.pickup,
              orElse: () => pickupPins.first,
            );
    }
    if (_destination == null && destPins.isNotEmpty) {
      _destination = _query.destination.isEmpty
          ? destPins.first
          : destPins.firstWhere(
              (pin) => pin.label == _query.destination,
              orElse: () => destPins.first,
            );
    }
  }

  void _openRoutes() {
    final route = _query.isComplete
        ? BookingRoutes.routeSelection
        : BookingRoutes.popularRoutes;
    Navigator.pushNamed(context, route, arguments: _query.toArguments());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.booking_selectOnMap),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is BookingError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.booking_selectOnMap),
            ),
            body: Center(child: Text(state.message)),
          );
        }

        final pickupPins = state is MapPinsLoaded
            ? state.pickup
            : <MapPinOption>[];
        final destPins = state is MapPinsLoaded
            ? state.destination
            : <MapPinOption>[];
        _syncPins(pickupPins, destPins);

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.booking_selectOnMap),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    BookingRoutes.popularRoutes,
                    arguments: _query.toArguments(),
                  );
                },
                child: Text(AppLocalizations.of(context)!.booking_popular),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleStyleMapView(
                      pickup: _pickup,
                      destination: _destination,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outline.withAlpha(120)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(24),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.booking_selectOnMapSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LocationRow(
                      color: scheme.secondary,
                      label: AppLocalizations.of(context)!.booking_pickupPoint,
                      value:
                          _pickup?.label ??
                          AppLocalizations.of(context)!.booking_notSet,
                      subtitle: _pickup?.subtitle ?? '',
                    ),
                    const SizedBox(height: 10),
                    _LocationRow(
                      color: scheme.error,
                      label: AppLocalizations.of(
                        context,
                      )!.booking_destinationPoint,
                      value:
                          _destination?.label ??
                          AppLocalizations.of(context)!.booking_notSet,
                      subtitle: _destination?.subtitle ?? '',
                    ),
                    const SizedBox(height: 16),
                    ClientButton(
                      label: _query.isComplete
                          ? AppLocalizations.of(context)!.booking_confirmRoute
                          : AppLocalizations.of(context)!.booking_popularRoutes,
                      expand: true,
                      onPressed: _openRoutes,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final Color color;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
