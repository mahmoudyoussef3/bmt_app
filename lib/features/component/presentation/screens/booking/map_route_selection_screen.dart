import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_mock_data.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking/google_style_map_view.dart';

/// Map-based pickup and destination selection (static UI, no map SDK).
class MapRouteSelectionScreen extends StatefulWidget {
  const MapRouteSelectionScreen({super.key});

  @override
  State<MapRouteSelectionScreen> createState() =>
      _MapRouteSelectionScreenState();
}

class _MapRouteSelectionScreenState extends State<MapRouteSelectionScreen> {
  late BookingSearchQuery _query;
  MapPinOption? _pickup = kMapPickupOptions.first;
  MapPinOption? _destination = kMapDestinationOptions.first;
  MapSelectionMode _mode = MapSelectionMode.pickup;
  int _pickupTapIndex = 0;
  int _destTapIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = BookingSearchQuery.of(context);
    if (_query.pickup.isNotEmpty) {
      _pickup = kMapPickupOptions.firstWhere(
        (p) => p.label == _query.pickup,
        orElse: () => kMapPickupOptions.first,
      );
    }
    if (_query.destination.isNotEmpty) {
      _destination = kMapDestinationOptions.firstWhere(
        (d) => d.label == _query.destination,
        orElse: () => kMapDestinationOptions.first,
      );
    }
  }

  void _onMapTap() {
    setState(() {
      if (_mode == MapSelectionMode.pickup) {
        _pickupTapIndex = (_pickupTapIndex + 1) % kMapPickupOptions.length;
        _pickup = kMapPickupOptions[_pickupTapIndex];
      } else {
        _destTapIndex = (_destTapIndex + 1) % kMapDestinationOptions.length;
        _destination = kMapDestinationOptions[_destTapIndex];
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
        const SnackBar(
          content: Text('Select pickup and destination on the map'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select on Map'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                BookingRoutes.popularRoutes,
                arguments: _query.toArguments(),
              );
            },
            child: const Text('Popular'),
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
                    label: 'Pickup',
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
                    label: 'Destination',
                    icon: Icons.location_on_rounded,
                    color: scheme.error,
                    selected: _mode == MapSelectionMode.destination,
                    onTap: () =>
                        setState(() => _mode = MapSelectionMode.destination),
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
                  onMapTap: _onMapTap,
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
                  'Tap the map to cycle ${_mode == MapSelectionMode.pickup ? 'pickup' : 'destination'} points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 12),
                _LocationRow(
                  color: scheme.secondary,
                  label: 'Pickup Point',
                  value: _pickup?.label ?? 'Not set',
                  subtitle: _pickup?.subtitle ?? '',
                ),
                const SizedBox(height: 10),
                _LocationRow(
                  color: scheme.error,
                  label: 'Destination Point',
                  value: _destination?.label ?? 'Not set',
                  subtitle: _destination?.subtitle ?? '',
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Confirm Route',
                  height: 50,
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ],
      ),
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
