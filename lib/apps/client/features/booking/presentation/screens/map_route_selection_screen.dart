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

/// Map-based pickup and destination selection (static UI, no map SDK).
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
  MapSelectionMode _mode = MapSelectionMode.pickup;
  int _pickupTapIndex = 0;
  int _destTapIndex = 0;
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

  void _onMapTap(List<MapPinOption> pickupPins, List<MapPinOption> destPins) {
    setState(() {
      if (_mode == MapSelectionMode.pickup && pickupPins.isNotEmpty) {
        _pickupTapIndex = (_pickupTapIndex + 1) % pickupPins.length;
        _pickup = pickupPins[_pickupTapIndex];
      } else if (destPins.isNotEmpty) {
        _destTapIndex = (_destTapIndex + 1) % destPins.length;
        _destination = destPins[_destTapIndex];
      }
      _query = _query.copyWith(
        pickup: _pickup?.label ?? '',
        destination: _destination?.label ?? '',
      );
    });
  }

  void _continue() {
    if (_pickup == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.booking_selectPickupDestMap,
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: _query.toArguments(),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeToggle(
                        label: AppLocalizations.of(context)!.booking_pickup,
                        icon: Icons.trip_origin_rounded,
                        color: scheme.secondary,
                        selected: _mode == MapSelectionMode.pickup,
                        onTap: () =>
                            setState(() => _mode = MapSelectionMode.pickup),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeToggle(
                        label: AppLocalizations.of(
                          context,
                        )!.booking_destination,
                        icon: Icons.location_on_rounded,
                        color: scheme.error,
                        selected: _mode == MapSelectionMode.destination,
                        onTap: () => setState(
                          () => _mode = MapSelectionMode.destination,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleStyleMapView(
                      pickup: _pickup,
                      destination: _destination,
                      selectionMode: _mode,
                      onMapTap: () => _onMapTap(pickupPins, destPins),
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
                      _mode == MapSelectionMode.pickup
                          ? AppLocalizations.of(context)!.booking_tapMapPickup
                          : AppLocalizations.of(context)!.booking_tapMapDest,
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
                      label: AppLocalizations.of(context)!.booking_confirmRoute,
                      expand: true,
                      onPressed: _continue,
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.withAlpha(40) : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : scheme.outline.withAlpha(100),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
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
