import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import '../../shared/domain/entities/operation_trip.dart';
import '../../shared/presentation/widgets/trip_fare_controllers.dart';
import '../../shared/presentation/widgets/trip_fare_fields.dart';
import '../../trip_creation/presentation/cubit/trip_creation_cubit.dart';

class TripCreationWizardDialog extends StatelessWidget {
  const TripCreationWizardDialog({super.key, this.prefillTrip});
  final OperationTrip? prefillTrip;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripCreationCubit, TripCreationState>(
      listener: (context, state) {
        if (state is TripCreationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is TripCreationSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الرحلة بنجاح'),
              backgroundColor: AppStatusColors.onSuccessContainer,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TripCreationLoading) {
          return const Dialog(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is TripCreationError) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'خطأ في التحميل',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(state.message),
                  const SizedBox(height: AppSpacing.large),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<TripCreationCubit>().loadWizardData(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TripCreationWizardDataLoaded) {
          final parsedRoutes = state.routes.map(_parseRoute).toList();
          final parsedVehicles = state.vehicles.map(_parseVehicle).toList();
          final parsedDrivers = state.drivers.map(_parseDriver).toList();

          return TripCreationWizard(
            routes: parsedRoutes,
            vehicles: parsedVehicles,
            drivers: parsedDrivers,
            prefillTrip: prefillTrip,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  OperationRoute _parseRoute(Map<String, dynamic> map) {
    final stationsList =
        (map['route_stations'] as List? ?? [])
            .map(
              (st) => RouteStation(
                id: st['id'] as String,
                name: st['name'] as String? ?? '',
                area: st['area'] as String? ?? '',
                arrivalOffset: st['arrival_offset'] as String? ?? '',
                departureOffset: st['departure_offset'] as String? ?? '',
                locationDescription:
                    st['location_description'] as String? ?? '',
                notes: st['notes'] as String? ?? '',
                order: st['sort_order'] as int? ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return OperationRoute(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      startCity: map['start_city'] as String? ?? '',
      endCity: map['end_city'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      distance: map['distance'] as String? ?? '',
      status: OperationRouteStatus.active,
      stations: stationsList,
      notes: const [],
    );
  }

  FleetVehicle _parseVehicle(Map<String, dynamic> map) {
    return FleetVehicle(
      id: map['id'] as String,
      vehicleCode: map['vehicle_code'] as String? ?? '',
      plateNumber: map['plate_number'] as String? ?? '',
      vehicleType: map['vehicle_type'] as String? ?? 'ميكروباص',
      brand: map['brand'] as String? ?? '',
      model:
          map['model'] as String? ?? map['vehicle_code'] as String? ?? 'مركبة',
      manufactureYear: 2024,
      color: '',
      capacity: map['capacity'] as int? ?? 14,
      seatLayoutType: '',
      imageUrl: '',
      notes: '',
      status: FleetVehicleStatus.active,
      seatConfiguration: SeatConfiguration.empty(),
      licenseExpiry: '',
      insuranceExpiry: '',
      inspectionExpiry: '',
    );
  }

  FleetDriver _parseDriver(Map<String, dynamic> map) {
    return FleetDriver(
      id: map['id'] as String,
      employeeCode: '',
      fullName: map['full_name'] as String? ?? 'سائق',
      phone: map['phone'] as String? ?? '',
      emergencyPhone: '',
      address: '',
      nationalId: '',
      profileImageUrl: '',
      licenseNumber: '',
      licenseExpiryDate: '',
      hireDate: '',
      notes: '',
      status: FleetDriverStatus.active,
      currentVehicleId: '',
    );
  }
}

class TripCreationWizard extends StatefulWidget {
  final List<OperationRoute> routes;
  final List<FleetVehicle> vehicles;
  final List<FleetDriver> drivers;
  final OperationTrip? prefillTrip;

  const TripCreationWizard({
    super.key,
    required this.routes,
    required this.vehicles,
    required this.drivers,
    this.prefillTrip,
  });

  @override
  State<TripCreationWizard> createState() => _TripCreationWizardState();
}

class _TripCreationWizardState extends State<TripCreationWizard> {
  // Selected values
  OperationRoute? _selectedRoute;
  FleetVehicle? _selectedVehicle;
  FleetDriver? _selectedDriver;

  // Schedule values
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _arrivalController = TextEditingController();
  Map<String, int> _stopWaits = {}; // stationId -> wait minutes
  final Map<String, String> _customArrivals = {}; // stationId -> custom HH:MM
  final Map<String, String> _customDepartures = {}; // stationId -> custom HH:MM

  /// The ONE fare configured for this trip: the ticket price plus the four
  /// package tiers derived from it. Applied to every boarding -> dropoff pair
  /// on submit, so `trip_pricing` is fully populated the moment the trip
  /// exists and the Client app never has to fall back to a guessed price.
  final _fare = TripFareControllers();

  @override
  void initState() {
    super.initState();
    _applyDefaultSchedule();
    final prefill = widget.prefillTrip;
    if (prefill != null) {
      _selectedRoute = widget.routes
          .where((r) => r.id == prefill.routeId)
          .firstOrNull;
      _selectedVehicle = widget.vehicles
          .where((v) => v.id == prefill.vehicleId)
          .firstOrNull;
      _selectedDriver = widget.drivers
          .where((d) => d.id == prefill.driverId)
          .firstOrNull;
      _timeController.text = prefill.departure;
      _arrivalController.text = prefill.arrival;
      _dateController.text = prefill.date;
      if (prefill.ticketPrice > 0) {
        _fare.oneTime.text = TripFareControllers.formatFare(prefill.ticketPrice);
        _fare.syncTiersFromBase();
      }
      if (_selectedRoute != null) _initializeWizardData();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _arrivalController.dispose();
    _fare.dispose();
    super.dispose();
  }

  void _initializeWizardData() {
    if (_selectedRoute == null) return;
    final points = _selectedRoute!.stations;

    // Initialize stop wait durations (default 2 mins)
    _stopWaits = {for (var st in points) st.id: 2};

    _syncArrivalFromRoute();
  }

  void _applyDefaultSchedule() {
    final now = DateTime.now().add(const Duration(hours: 1));
    final rounded = DateTime(now.year, now.month, now.day, now.hour);
    _dateController.text = _formatDate(rounded);
    _timeController.text = '${rounded.hour.toString().padLeft(2, '0')}:00:00';
    _arrivalController.text =
        '${rounded.add(const Duration(hours: 1)).hour.toString().padLeft(2, '0')}:00:00';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _syncArrivalFromRoute() {
    if (_timeController.text.isEmpty) return;
    final departure = _parseClock(_timeController.text);
    if (departure == null) return;
    final minutes = _selectedRoute == null
        ? 60
        : _durationMinutesFromRoute(_selectedRoute!);
    final arrival = departure.add(Duration(minutes: minutes));
    _arrivalController.text =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}:00';
  }

  DateTime? _parseClock(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  int _durationMinutesFromRoute(OperationRoute route) {
    final lastStationOffset = route.stations.isEmpty
        ? ''
        : route.stations.last.arrivalOffset;
    final fromStation = _parseMinutes(lastStationOffset);
    if (fromStation > 0 && fromStation != 15) return fromStation;
    final text = route.duration
        .replaceAll('ساعات', 'س')
        .replaceAll('ساعة', 'س')
        .replaceAll('دقائق', 'د')
        .replaceAll('دقيقة', 'د')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
    final hourMatch = RegExp(r'(\d+)\s*س').firstMatch(text);
    final minuteMatch = RegExp(r'(\d+)\s*د').firstMatch(text);
    final hours = int.tryParse(hourMatch?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(minuteMatch?.group(1) ?? '') ?? 0;
    if (hours > 0 || minutes > 0) return hours * 60 + minutes;
    return _parseMinutes(text);
  }

  int _parseMinutes(String offset) {
    final clean = offset
        .replaceAll('دقيقة', '')
        .replaceAll('دقائق', '')
        .replaceAll(' ', '')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .trim();
    return int.tryParse(clean) ?? 15;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width - 32).clamp(380.0, 1280.0);
    final dialogHeight = (viewport.height - 32).clamp(620.0, 860.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildPlannerHeader(scheme),
            Expanded(child: _buildPlannerWorkspace()),
            _buildPlannerFooter(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerHeader(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.radiusLarge),
          topRight: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(bottom: BorderSide(color: scheme.outline.withAlpha(50))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.route_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.prefillTrip == null
                      ? 'مخطط رحلة جديد'
                      : 'نسخ رحلة وتشغيلها',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'اختر الأساسيات، راجع الجاهزية، ثم أنشئ الرحلة من شاشة واحدة.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _PlannerReadinessPill(ready: _isTripReady()),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final content = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 390, child: _buildSelectionColumn()),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(child: _buildPlanningColumn()),
                ],
              )
            : Column(
                children: [
                  _buildSelectionColumn(),
                  const SizedBox(height: AppSpacing.large),
                  _buildPlanningColumn(),
                ],
              );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: content,
        );
      },
    );
  }

  Widget _buildPlannerFooter(ColorScheme scheme) {
    final ready = _isTripReady();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTokens.radiusLarge),
          bottomRight: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(50))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('إلغاء'),
          ),
          const SizedBox(width: AppSpacing.small),
          TextButton.icon(
            onPressed: _resetPlanner,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة ضبط'),
          ),
          const Spacer(),
          Text(
            ready ? 'كل شيء جاهز للتشغيل' : _readinessMessage(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ready ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: ready ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          FilledButton.icon(
            onPressed: ready ? _onSubmitTrip : null,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('إنشاء الرحلة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionColumn() {
    return Column(
      children: [
        _PlannerSectionCard(
          title: 'المسار',
          icon: Icons.alt_route_rounded,
          done: _selectedRoute != null,
          child: _buildRoutePicker(),
        ),
        const SizedBox(height: AppSpacing.medium),
        _PlannerSectionCard(
          title: 'المركبة',
          icon: Icons.airport_shuttle_rounded,
          done: _selectedVehicle != null,
          child: _buildVehiclePicker(),
        ),
        const SizedBox(height: AppSpacing.medium),
        _PlannerSectionCard(
          title: 'السائق',
          icon: Icons.person_outline_rounded,
          done: _selectedDriver != null,
          child: _buildDriverPicker(),
        ),
      ],
    );
  }

  Widget _buildPlanningColumn() {
    return Column(
      children: [
        _buildPlannerSummary(),
        const SizedBox(height: AppSpacing.medium),
        _PlannerSectionCard(
          title: 'الجدولة والتوقيت',
          icon: Icons.calendar_month_rounded,
          done:
              _dateController.text.isNotEmpty &&
              _timeController.text.isNotEmpty &&
              _arrivalController.text.isNotEmpty,
          child: _buildSchedulePanel(),
        ),
        const SizedBox(height: AppSpacing.medium),
        _PlannerSectionCard(
          title: 'التسعير',
          icon: Icons.payments_outlined,
          done: _fare.isValid,
          child: _buildPricingPanel(),
        ),
        const SizedBox(height: AppSpacing.medium),
        _PlannerSectionCard(
          title: 'المحطات',
          icon: Icons.pin_drop_outlined,
          done: _selectedRoute?.stations.isNotEmpty ?? false,
          child: _buildStationTimelineCompact(),
        ),
      ],
    );
  }

  Widget _buildRoutePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedRoute?.id,
          decoration: const InputDecoration(
            labelText: 'اختر المسار',
            prefixIcon: Icon(Icons.route_outlined),
          ),
          items: widget.routes
              .map(
                (route) => DropdownMenuItem(
                  value: route.id,
                  child: Text(route.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (id) {
            final route = widget.routes.where((r) => r.id == id).firstOrNull;
            if (route == null) return;
            setState(() {
              _selectedRoute = route;
              _initializeWizardData();
            });
          },
        ),
        if (_selectedRoute != null) ...[
          const SizedBox(height: AppSpacing.medium),
          _MiniInfoGrid(
            items: [
              ('من', _selectedRoute!.startCity),
              ('إلى', _selectedRoute!.endCity),
              ('محطات', '${_selectedRoute!.stations.length}'),
              ('مدة', _selectedRoute!.duration),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVehiclePicker() {
    final activeVehicles = widget.vehicles
        .where((vehicle) => vehicle.status == FleetVehicleStatus.active)
        .toList();
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedVehicle?.id,
          decoration: const InputDecoration(
            labelText: 'اختر المركبة',
            prefixIcon: Icon(Icons.directions_bus_outlined),
          ),
          items: activeVehicles
              .map(
                (vehicle) => DropdownMenuItem(
                  value: vehicle.id,
                  child: Text(
                    '${vehicle.plateNumber} • ${vehicle.capacity} مقعد',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            final vehicle = activeVehicles
                .where((candidate) => candidate.id == id)
                .firstOrNull;
            if (vehicle == null) return;
            setState(() => _selectedVehicle = vehicle);
          },
        ),
        if (_selectedVehicle != null) ...[
          const SizedBox(height: AppSpacing.medium),
          _SelectedAssetTile(
            title: _selectedVehicle!.model,
            subtitle:
                '${_selectedVehicle!.plateNumber} • ${_selectedVehicle!.type}',
            trailing: '${_selectedVehicle!.capacity} مقعد',
            icon: Icons.airline_seat_recline_normal,
          ),
        ],
      ],
    );
  }

  Widget _buildDriverPicker() {
    final activeDrivers = widget.drivers
        .where((driver) => driver.status == FleetDriverStatus.active)
        .toList();
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedDriver?.id,
          decoration: const InputDecoration(
            labelText: 'اختر السائق',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: activeDrivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(
                    '${driver.name} • ${driver.phone}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            final driver = activeDrivers
                .where((candidate) => candidate.id == id)
                .firstOrNull;
            if (driver == null) return;
            setState(() => _selectedDriver = driver);
          },
        ),
        if (_selectedDriver != null) ...[
          const SizedBox(height: AppSpacing.medium),
          _SelectedAssetTile(
            title: _selectedDriver!.name,
            subtitle: _selectedDriver!.phone,
            trailing: _selectedDriver!.status.label,
            icon: Icons.person_outline_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildPlannerSummary() {
    final scheme = Theme.of(context).colorScheme;
    final ready = _isTripReady();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ready
                ? scheme.primaryContainer
                : scheme.tertiaryContainer,
            child: Icon(
              ready ? Icons.verified_outlined : Icons.pending_actions_rounded,
              color: ready ? scheme.primary : scheme.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'الخطة جاهزة للتشغيل' : 'أكمل عناصر الخطة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ready ? _tripSummaryLine() : _readinessMessage(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              _PlannerStatusChip(label: 'مسار', done: _selectedRoute != null),
              _PlannerStatusChip(
                label: 'مركبة',
                done: _selectedVehicle != null,
              ),
              _PlannerStatusChip(label: 'سائق', done: _selectedDriver != null),
              _PlannerStatusChip(
                label: 'موعد',
                done:
                    _dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty &&
                    _arrivalController.text.isNotEmpty,
              ),
              _PlannerStatusChip(label: 'سعر', done: _fare.isValid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickTripDate,
                decoration: const InputDecoration(
                  labelText: 'تاريخ الرحلة',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _timeController,
                readOnly: true,
                onTap: _pickDepartureTime,
                decoration: const InputDecoration(
                  labelText: 'وقت الانطلاق',
                  prefixIcon: Icon(Icons.access_time_rounded),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _arrivalController,
                readOnly: true,
                onTap: _pickArrivalTime,
                decoration: const InputDecoration(
                  labelText: 'وقت الوصول',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            ActionChip(
              avatar: const Icon(Icons.today_outlined, size: 18),
              label: const Text('اليوم'),
              onPressed: () => _setDateOffset(0),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_outlined, size: 18),
              label: const Text('غداً'),
              onPressed: () => _setDateOffset(1),
            ),
            ActionChip(
              avatar: const Icon(Icons.update_rounded, size: 18),
              label: const Text('بعد ساعة'),
              onPressed: _setNextHourDeparture,
            ),
            ActionChip(
              avatar: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('حساب الوصول من المسار'),
              onPressed: () => setState(_syncArrivalFromRoute),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingPanel() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أدخل سعر التذكرة، وسيتم حساب أسعار الباقات تلقائياً. يمكنك تعديل أي باقة يدوياً.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.medium),
        TripFareFields(
          controllers: _fare,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'تُطبَّق هذه الأسعار على جميع مقاطع الصعود والنزول في هذه الرحلة، '
          'وتظهر مباشرة في تطبيق العميل. لتسعير مقطع بعينه بسعر مختلف، '
          'استخدم تبويب التسعير بعد إنشاء الرحلة.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStationTimelineCompact() {
    final route = _selectedRoute;
    if (route == null) {
      return const Text('اختر مساراً لعرض محطات الرحلة.');
    }
    if (route.stations.isEmpty) {
      return const Text('المسار المختار لا يحتوي على محطات.');
    }
    return Column(
      children: route.stations.indexed.map((entry) {
        final (index, station) = entry;
        final wait = _stopWaits[station.id] ?? 2;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: _CompactStationRow(
            index: index,
            station: station,
            wait: wait,
            onWaitChanged: (value) {
              setState(() => _stopWaits[station.id] = value);
            },
          ),
        );
      }).toList(),
    );
  }

  bool _isTripReady() {
    return _selectedRoute != null &&
        _selectedVehicle != null &&
        _selectedDriver != null &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _arrivalController.text.isNotEmpty &&
        _fare.isValid;
  }

  String _readinessMessage() {
    final missing = <String>[
      if (_selectedRoute == null) 'المسار',
      if (_selectedVehicle == null) 'المركبة',
      if (_selectedDriver == null) 'السائق',
      if (_dateController.text.isEmpty ||
          _timeController.text.isEmpty ||
          _arrivalController.text.isEmpty)
        'الموعد',
      if (!_fare.isValid) 'السعر',
    ];
    return missing.isEmpty ? 'جاهز' : 'المتبقي: ${missing.join('، ')}';
  }

  String _tripSummaryLine() {
    return '${_selectedRoute?.name ?? '-'} • ${_selectedVehicle?.plateNumber ?? '-'} • ${_selectedDriver?.name ?? '-'} • ${_dateController.text} ${_timeController.text}';
  }

  void _resetPlanner() {
    setState(() {
      _selectedRoute = null;
      _selectedVehicle = null;
      _selectedDriver = null;
      _stopWaits = {};
      _customArrivals.clear();
      _customDepartures.clear();
      _fare.clear();
      _applyDefaultSchedule();
    });
  }

  Future<void> _pickTripDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() => _dateController.text = _formatDate(date));
  }

  Future<void> _pickDepartureTime() async {
    final initial = _timeOfDayFromText(_timeController.text);
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    setState(() {
      _timeController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      _syncArrivalFromRoute();
    });
  }

  Future<void> _pickArrivalTime() async {
    final initial = _timeOfDayFromText(_arrivalController.text);
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    setState(() {
      _arrivalController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    });
  }

  TimeOfDay _timeOfDayFromText(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(hour: hour ?? 8, minute: minute ?? 0);
  }

  void _setDateOffset(int days) {
    final date = DateTime.now().add(Duration(days: days));
    setState(() => _dateController.text = _formatDate(date));
  }

  void _setNextHourDeparture() {
    final now = DateTime.now().add(const Duration(hours: 1));
    final next = DateTime(now.year, now.month, now.day, now.hour);
    setState(() {
      _dateController.text = _formatDate(next);
      _timeController.text = '${next.hour.toString().padLeft(2, '0')}:00:00';
      _syncArrivalFromRoute();
    });
  }

  void _onSubmitTrip() async {
    final customStationTimesList = _selectedRoute!.stations.map((st) {
      return {
        'route_point_id': st.id,
        'arrival_offset': _customArrivals[st.id] ?? '',
        'departure_offset': _customDepartures[st.id] ?? '',
      };
    }).toList();

    final input = CreateTripInput(
      routeId: _selectedRoute!.id,
      route: _selectedRoute!.name,
      driverId: _selectedDriver!.id,
      driver: _selectedDriver!.name,
      vehicleId: _selectedVehicle!.id,
      vehicle: _selectedVehicle!.plateNumber,
      date: _dateController.text,
      departure: _timeController.text,
      arrival: _arrivalController.text,
      capacity: _selectedVehicle!.capacity,
      ticketPrice: _fare.baseFare,
      packageTierPrices: _fare.tierPrices,
      currency: 'ج.م',
      customStationTimes: customStationTimesList,
    );

    final cubit = context.read<TripCreationCubit>();
    // Pricing rows are expanded from `input` inside CreateTripUseCase, once
    // the trip's route points exist to key them by.
    final created = await cubit.submitTrip(input, const []);

    if (mounted && created != null) {
      Navigator.of(context).pop(); // Close wizard dialog
    }
  }
}

class _PlannerSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool done;
  final Widget child;

  const _PlannerSectionCard({
    required this.title,
    required this.icon,
    required this.done,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: done ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

class _PlannerReadinessPill extends StatelessWidget {
  final bool ready;

  const _PlannerReadinessPill({required this.ready});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        ready ? Icons.verified_outlined : Icons.pending_outlined,
        size: 18,
        color: ready ? scheme.primary : scheme.onSurfaceVariant,
      ),
      label: Text(ready ? 'جاهز' : 'قيد التجهيز'),
      backgroundColor: ready
          ? scheme.primaryContainer.withAlpha(90)
          : scheme.surface,
      side: BorderSide(color: scheme.outline.withAlpha(90)),
    );
  }
}

class _PlannerStatusChip extends StatelessWidget {
  final String label;
  final bool done;

  const _PlannerStatusChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        done ? Icons.check_rounded : Icons.more_horiz_rounded,
        size: 16,
        color: done ? scheme.primary : scheme.onSurfaceVariant,
      ),
      label: Text(label),
      backgroundColor: done
          ? scheme.primaryContainer.withAlpha(70)
          : scheme.surfaceContainerHighest.withAlpha(60),
      side: BorderSide(color: scheme.outline.withAlpha(60)),
    );
  }
}

class _MiniInfoGrid extends StatelessWidget {
  final List<(String, String)> items;

  const _MiniInfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: items.map((item) {
        final (label, value) = item;
        return Container(
          width: 160,
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(60),
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SelectedAssetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;

  const _SelectedAssetTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(55),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.primary.withAlpha(70)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.surface,
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(trailing, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _CompactStationRow extends StatelessWidget {
  final int index;
  final RouteStation station;
  final int wait;
  final ValueChanged<int> onWaitChanged;

  const _CompactStationRow({
    required this.index,
    required this.station,
    required this.wait,
    required this.onWaitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 15, child: Text('${index + 1}')),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  station.area,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              initialValue: wait,
              decoration: const InputDecoration(labelText: 'انتظار'),
              items: [1, 2, 3, 5, 8, 10, 15, 20, 30]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m د')))
                  .toList(),
              onChanged: (value) => onWaitChanged(value ?? wait),
            ),
          ),
        ],
      ),
    );
  }
}
