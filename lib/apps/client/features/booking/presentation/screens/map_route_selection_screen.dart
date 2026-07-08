import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Selects real pickup and destination stations and previews them on a map.
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
  bool _didRestoreSelection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _query = bookingQueryFromContext(context);
    _didLoad = true;
    context.read<BookingCubit>().loadMapPins();
  }

  void _restoreSelection(
    List<MapPinOption> pickupPins,
    List<MapPinOption> destinationPins,
  ) {
    if (_didRestoreSelection) return;
    _didRestoreSelection = true;
    _pickup = _findByLabel(pickupPins, _query.pickup);
    _destination = _findByLabel(destinationPins, _query.destination);
  }

  MapPinOption? _findByLabel(List<MapPinOption> pins, String label) {
    if (label.isEmpty) return null;
    for (final pin in pins) {
      if (pin.label == label) return pin;
    }
    return null;
  }

  Future<void> _chooseStation({
    required String title,
    required List<MapPinOption> pins,
    required MapPinOption? selected,
    required ValueChanged<MapPinOption> onSelected,
  }) async {
    final result = await showModalBottomSheet<MapPinOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _StationPickerSheet(title: title, pins: pins, selected: selected),
    );
    if (result != null && mounted) onSelected(result);
  }

  void _selectPickup(MapPinOption pin) {
    setState(() {
      _pickup = pin;
      _query = _query.copyWith(routeId: '', pickup: pin.label);
    });
  }

  void _selectDestination(MapPinOption pin) {
    setState(() {
      _destination = pin;
      _query = _query.copyWith(routeId: '', destination: pin.label);
    });
  }

  void _openRoutes() {
    if (!_query.isComplete) return;
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.booking_selectOnMap)),
            body: const _MapLoadingState(),
          );
        }
        if (state is BookingError) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.booking_selectOnMap)),
            body: _MapErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<BookingCubit>().loadMapPins(force: true),
            ),
          );
        }

        final pickupPins = state is MapPinsLoaded
            ? state.pickup
            : <MapPinOption>[];
        final destinationPins = state is MapPinsLoaded
            ? state.destination
            : <MapPinOption>[];
        _restoreSelection(pickupPins, destinationPins);

        return Scaffold(
          backgroundColor: ClientColors.surfaceSubtleFor(context),
          appBar: AppBar(
            title: Text(localizations.booking_selectOnMap),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    context.read<BookingCubit>().loadMapPins(force: true),
              ),
              ClientButton.text(
                label: localizations.booking_popular,
                onPressed: () => Navigator.pushNamed(
                  context,
                  BookingRoutes.popularRoutes,
                  arguments: _query.toArguments(),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: EasyWayRouteMapView(
                  pickup: _pickup,
                  destination: _destination,
                  cameraPadding: const EdgeInsets.fromLTRB(48, 64, 48, 290),
                ),
              ),
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: _SelectionPanel(
                        pickup: _pickup,
                        destination: _destination,
                        pickupEnabled: pickupPins.isNotEmpty,
                        destinationEnabled: destinationPins.isNotEmpty,
                        onPickup: () => _chooseStation(
                          title: localizations.booking_pickupPoint,
                          pins: pickupPins,
                          selected: _pickup,
                          onSelected: _selectPickup,
                        ),
                        onDestination: () => _chooseStation(
                          title: localizations.booking_destinationPoint,
                          pins: destinationPins,
                          selected: _destination,
                          onSelected: _selectDestination,
                        ),
                        onConfirm: _query.isComplete ? _openRoutes : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.pickup,
    required this.destination,
    required this.pickupEnabled,
    required this.destinationEnabled,
    required this.onPickup,
    required this.onDestination,
    required this.onConfirm,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final bool pickupEnabled;
  final bool destinationEnabled;
  final VoidCallback onPickup;
  final VoidCallback onDestination;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sheet),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.lg(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.booking_selectOnMapSubtitle,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 12),
          _LocationSelector(
            icon: Icons.trip_origin_rounded,
            color: ClientColors.journeyGreen,
            label: localizations.booking_pickupPoint,
            value: pickup?.label ?? localizations.booking_notSet,
            subtitle: pickupEnabled
                ? pickup?.subtitle ?? 'Tap to choose a pickup station'
                : 'No mapped pickup stations are available',
            enabled: pickupEnabled,
            onTap: onPickup,
          ),
          const SizedBox(height: 8),
          _LocationSelector(
            icon: Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.error,
            label: localizations.booking_destinationPoint,
            value: destination?.label ?? localizations.booking_notSet,
            subtitle: destinationEnabled
                ? destination?.subtitle ?? 'Tap to choose a destination'
                : 'No mapped destinations are available',
            enabled: destinationEnabled,
            onTap: onDestination,
          ),
          const SizedBox(height: 14),
          ClientButton(
            label: localizations.booking_confirmRoute,
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ClientColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textTertiaryFor(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: enabled
                    ? ClientColors.primaryFor(context)
                    : ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationPickerSheet extends StatelessWidget {
  const _StationPickerSheet({
    required this.title,
    required this.pins,
    required this.selected,
  });

  final String title;
  final List<MapPinOption> pins;
  final MapPinOption? selected;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(title, style: ClientTypography.headingSmall(context)),
          ),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: pins.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final pin = pins[index];
                final isSelected = selected?.label == pin.label;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: ClientColors.primaryFor(
                    context,
                  ).withAlpha(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClientRadius.md),
                  ),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected
                        ? ClientColors.primaryFor(context)
                        : ClientColors.textTertiaryFor(context),
                  ),
                  title: Text(
                    pin.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: pin.subtitle.isEmpty ? null : Text(pin.subtitle),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: ClientColors.primaryFor(context),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, pin),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: ClientColors.surfaceMutedFor(context)),
        ),
        PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: ClientSkeleton(
              height: 258,
              borderRadius: ClientRadius.sheet,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapErrorState extends StatelessWidget {
  const _MapErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 52,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 14),
            Text(
              'Map could not be loaded',
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 18),
            ClientButton(label: 'Try again', expand: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
