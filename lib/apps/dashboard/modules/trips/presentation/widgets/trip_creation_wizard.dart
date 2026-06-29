import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_driver.dart';
import '../../shared/domain/entities/operation_trip.dart';
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
  int _currentStep = 0;

  // Selected values
  OperationRoute? _selectedRoute;
  FleetVehicle? _selectedVehicle;
  FleetDriver? _selectedDriver;

  // Schedule values
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _priceController = TextEditingController();
  Map<String, int> _stopWaits = {}; // stationId -> wait minutes
  final Map<String, String> _customArrivals = {}; // stationId -> custom HH:MM
  final Map<String, String> _customDepartures = {}; // stationId -> custom HH:MM

  // Pricing values
  // Matrix format: fromPointId_toPointId -> prices
  Map<String, _PricingConfig> _pricingMatrix = {};

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
      _priceController.text = prefill.ticketPrice > 0
          ? prefill.ticketPrice.toStringAsFixed(0)
          : _priceController.text;
      if (_selectedRoute != null) _initializeWizardData();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _arrivalController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeWizardData() {
    if (_selectedRoute == null) return;
    final points = _selectedRoute!.stations;

    // Initialize stop wait durations (default 2 mins)
    _stopWaits = {for (var st in points) st.id: 2};

    // Initialize stop-to-stop combinations
    _pricingMatrix = {};
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final key = '${points[i].id}_${points[j].id}';
        // Estimate price based on distance/offset order
        final dist = (j - i) * 15.0;
        final baseOneTime = dist > 0 ? dist : 15.0;
        _pricingMatrix[key] = _PricingConfig(
          oneTime: baseOneTime,
          fiveDays: baseOneTime * 5 * 0.9, // 10% discount
          tenDays: baseOneTime * 10 * 0.85, // 15% discount
          monthly: baseOneTime * 22 * 0.8, // 20% discount
          threeMonths: baseOneTime * 66 * 0.75, // 25% discount
        );
      }
    }
    if (_priceController.text.trim().isEmpty) {
      final firstPrice = _pricingMatrix.values.firstOrNull?.oneTime ?? 15.0;
      _priceController.text = firstPrice.toStringAsFixed(0);
    }
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
          done: (double.tryParse(_priceController.text.trim()) ?? 0) > 0,
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
              _PlannerStatusChip(
                label: 'سعر',
                done: (double.tryParse(_priceController.text.trim()) ?? 0) > 0,
              ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: FleetInputFormatters.money,
            decoration: const InputDecoration(
              labelText: 'سعر التذكرة القياسي',
              suffixText: 'ج.م',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Text(
            'سيتم استخدام السعر القياسي لإنشاء الرحلة الآن. يمكن ضبط مصفوفة أسعار تفصيلية لاحقاً من تبويب التسعير داخل تفاصيل الرحلة.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
        (double.tryParse(_priceController.text.trim()) ?? 0) > 0;
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
      if ((double.tryParse(_priceController.text.trim()) ?? 0) <= 0) 'السعر',
    ];
    return missing.isEmpty ? 'جاهز' : 'المتبقي: ${missing.join('، ')}';
  }

  String _tripSummaryLine() {
    return '${_selectedRoute?.name ?? '-'} • ${_selectedVehicle?.plateNumber ?? '-'} • ${_selectedDriver?.name ?? '-'} • ${_dateController.text} ${_timeController.text}';
  }

  void _resetPlanner() {
    setState(() {
      _currentStep = 0;
      _selectedRoute = null;
      _selectedVehicle = null;
      _selectedDriver = null;
      _stopWaits = {};
      _customArrivals.clear();
      _customDepartures.clear();
      _pricingMatrix = {};
      _priceController.clear();
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

  // ignore: unused_element
  Widget _buildHeader(ColorScheme scheme) {
    final stepTitles = [
      'اختيار المسار',
      'اختيار المركبة',
      'اختيار السائق',
      'جدولة الرحلة والمحطات',
      'تسعير الرحلة',
      'مراجعة الرحلة وتأكيدها',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.radiusLarge),
          topRight: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(bottom: BorderSide(color: scheme.outline.withAlpha(50))),
      ),
      child: Row(
        children: [
          Icon(Icons.add_road_rounded, color: scheme.primary, size: 28),
          const SizedBox(width: AppSpacing.medium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مساعد إنشاء رحلة جديدة',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'الخطوة ${_currentStep + 1} من 6: ${stepTitles[_currentStep]}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStepProgressBar(ColorScheme scheme) {
    return Container(
      height: 4,
      width: double.infinity,
      color: scheme.outline.withAlpha(30),
      child: Row(
        children: List.generate(6, (index) {
          final active = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              color: active ? scheme.primary : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1RouteSelection();
      case 1:
        return _buildStep2VehicleSelection();
      case 2:
        return _buildStep3DriverSelection();
      case 3:
        return _buildStep4Scheduling();
      case 4:
        return _buildStep5PricingMatrix();
      case 5:
        return _buildStep7Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: ROUTE SELECTION ---
  Widget _buildStep1RouteSelection() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر نموذج المسار لتشغيل هذه الرحلة:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.routes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
                mainAxisExtent: 140,
              ),
              itemBuilder: (context, index) {
                final route = widget.routes[index];
                final selected = _selectedRoute?.id == route.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRoute = route;
                      _initializeWizardData();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer.withAlpha(40)
                          : scheme.surface,
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withAlpha(60),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? scheme.primary : null,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              Text(
                                'البداية: ${route.startCity} • النهاية: ${route.endCity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${route.stations.length} محطات',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  const SizedBox(width: AppSpacing.medium),
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 14,
                                    color: scheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    route.distance,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  const SizedBox(width: AppSpacing.medium),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    route.duration,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- STEP 2: VEHICLE SELECTION ---
  Widget _buildStep2VehicleSelection() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر مركبة لتشغيل الرحلة (السعة تحدد تلقائياً من إعداد المركبة):',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.vehicles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
                mainAxisExtent: 150,
              ),
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                final selected = _selectedVehicle?.id == vehicle.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVehicle = vehicle;
                      // If selected driver is assigned to another vehicle, reset
                      if (_selectedDriver != null &&
                          _selectedDriver!.currentVehicle !=
                              vehicle.plateNumber) {
                        _selectedDriver = null;
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer.withAlpha(40)
                          : scheme.surface,
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withAlpha(60),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    vehicle.model,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: selected
                                              ? scheme.primary
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpacing.small),
                                  StatusChip(label: vehicle.status.label),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              Text(
                                'رقم اللوحة: ${vehicle.plateNumber}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'النوع: ${vehicle.type}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.airline_seat_recline_normal,
                                    size: 16,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'السعة: ${vehicle.capacity} مقعد',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- STEP 3: DRIVER SELECTION ---
  Widget _buildStep3DriverSelection() {
    final scheme = Theme.of(context).colorScheme;
    final availableDrivers = widget.drivers
        .where((d) => d.status == FleetDriverStatus.active)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر سائقاً متاحاً لتشغيل الرحلة:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableDrivers.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
                mainAxisExtent: 140,
              ),
              itemBuilder: (context, index) {
                final driver = availableDrivers[index];
                final selected = _selectedDriver?.id == driver.id;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedDriver = driver);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer.withAlpha(40)
                          : scheme.surface,
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withAlpha(60),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: scheme.primary.withAlpha(30),
                          child: Text(
                            driver.avatarInitials,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? scheme.primary : null,
                                    ),
                              ),
                              Text(
                                'رقم الهاتف: ${driver.phone}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                'المركبة الحالية: ${driver.currentVehicle}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                'آخر رحلة: ${driver.currentRoute}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- STEP 4: SCHEDULING & ESTIMATED TIMELINE ---
  Widget _buildStep4Scheduling() {
    final scheme = Theme.of(context).colorScheme;
    if (_selectedRoute == null) {
      return const Center(child: Text('يرجى اختيار مسار أولاً'));
    }

    final stations = _selectedRoute!.stations;
    // We will build the timeline live based on start time and offsets
    final startTimeParts = _timeController.text.split(':');
    int startHour = 7;
    int startMin = 0;
    if (startTimeParts.length >= 2) {
      startHour = int.tryParse(startTimeParts[0]) ?? 7;
      startMin = int.tryParse(startTimeParts[1]) ?? 0;
    }

    String getTimeStr(int additionalMinutes) {
      final totalMin = startMin + additionalMinutes;
      final hr = (startHour + totalMin ~/ 60) % 24;
      final mn = totalMin % 60;
      final hrStr = hr.toString().padLeft(2, '0');
      final mnStr = mn.toString().padLeft(2, '0');
      return '$hrStr:$mnStr';
    }

    int accumulatedMinutes = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جدولة موعد انطلاق الرحلة:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth >= 840
                ? (constraints.maxWidth - AppSpacing.medium * 2) / 3
                : constraints.maxWidth >= 560
                ? (constraints.maxWidth - AppSpacing.medium) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppSpacing.medium,
              runSpacing: AppSpacing.medium,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        _dateController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        setState(() {});
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الرحلة',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _timeController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                        setState(() {});
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'وقت الانطلاق',
                      hintText: 'HH:MM:SS',
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: _arrivalController,
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _arrivalController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                        setState(() {});
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'وقت الوصول',
                      hintText: 'HH:MM:SS',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(
          'مخطط مواقيت نقاط الوقوف المتوقعة:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
            final wait = _stopWaits[station.id] ?? 2;

            // Extract numeric offset or assume an increment
            final offsetNum = _parseMinutes(station.arrivalOffset);
            accumulatedMinutes += offsetNum;

            final arrivalTime =
                _customArrivals[station.id] ??
                (index == 0
                    ? _timeController.text
                    : getTimeStr(accumulatedMinutes));
            final departureTime =
                _customDepartures[station.id] ??
                getTimeStr(accumulatedMinutes + wait);

            // Accumulate wait for the next station
            accumulatedMinutes += wait;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary.withAlpha(20),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'النطاق: ${station.area}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    _TimeIndicator(
                      label: 'وصول متوقع',
                      time: arrivalTime,
                      onTap: index == 0
                          ? null
                          : () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _customArrivals[station.id] =
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<int>(
                        initialValue: wait,
                        decoration: const InputDecoration(
                          labelText: 'فترة الانتظار',
                        ),
                        items: [1, 2, 3, 5, 8, 10, 15, 20, 30]
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m دقائق'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _stopWaits[station.id] = val ?? 2;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    _TimeIndicator(
                      label: 'تحرك متوقع',
                      time: departureTime,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _customDepartures[station.id] =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
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

  // --- STEP 5: PRICING MATRIX ---
  Widget _buildStep5PricingMatrix() {
    final scheme = Theme.of(context).colorScheme;
    if (_selectedRoute == null) {
      return const Center(child: Text('يرجى اختيار مسار أولاً'));
    }

    final stations = _selectedRoute!.stations;
    if (stations.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'عفواً، هذا المسار لا يحتوي على نقاط وقوف كافية (يجب أن يحتوي على محطتين على الأقل) لإعداد التسعير. يرجى تعديل المسار أو اختيار مسار آخر.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سعر التذكرة القياسي:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'أدخل سعر التذكرة القياسي. سيتم تطبيقه على جميع مقاطع الصعود والنزول المتاحة بدون أي فئات VIP أو أسعار مميزة.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          width: 280,
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: FleetInputFormatters.money,
            decoration: const InputDecoration(
              labelText: 'سعر التذكرة',
              suffixText: 'ج.م',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: scheme.outline.withAlpha(50)),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(80),
                ),
                children: [
                  const TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'من \\ إلى',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ...stations
                      .sublist(1)
                      .map(
                        (st) => TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              st.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              // Body Rows
              ...List.generate(stations.length - 1, (i) {
                final fromSt = stations[i];
                return TableRow(
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        color: scheme.surfaceContainerHighest.withAlpha(40),
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          fromSt.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...List.generate(stations.length - 1, (j) {
                      final toSt = stations[j + 1];
                      final isAvailable = fromSt.order < toSt.order;

                      if (!isAvailable) {
                        return TableCell(
                          child: Container(
                            color: scheme.outline.withAlpha(15),
                            height: 60,
                            child: const Center(child: Text('-')),
                          ),
                        );
                      }

                      final key = '${fromSt.id}_${toSt.id}';
                      final config =
                          _pricingMatrix[key] ?? _PricingConfig(oneTime: 15);

                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: TextFormField(
                            initialValue: config.oneTime.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            inputFormatters: FleetInputFormatters.money,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              suffixText: 'ج.م',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val) ?? 15.0;
                              setState(() {
                                _pricingMatrix[key] = config.copyWith(
                                  oneTime: parsed,
                                  fiveDays: parsed * 5 * 0.9,
                                  tenDays: parsed * 10 * 0.85,
                                  monthly: parsed * 22 * 0.8,
                                  threeMonths: parsed * 66 * 0.75,
                                );
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 6: PACKAGE PRICING ---
  // ignore: unused_element
  Widget _buildStep6PackagesPricing() {
    final scheme = Theme.of(context).colorScheme;
    if (_selectedRoute == null) {
      return const Center(child: Text('يرجى اختيار مسار أولاً'));
    }

    final stations = _selectedRoute!.stations;
    // Filter active segments (where from.order < to.order)
    final segments = <_SegmentItem>[];
    for (int i = 0; i < stations.length; i++) {
      for (int j = i + 1; j < stations.length; j++) {
        segments.add(_SegmentItem(from: stations[i], to: stations[j]));
      }
    }

    // Default to the first segment
    if (segments.isEmpty) return const SizedBox.shrink();
    var currentSegment = segments.first;

    return StatefulBuilder(
      builder: (context, setSubState) {
        final key = '${currentSegment.from.id}_${currentSegment.to.id}';
        final config = _pricingMatrix[key] ?? _PricingConfig(oneTime: 15);

        // Package descriptions
        final packagesList = [
          (
            name: 'اشتراك أسبوع عمل كامل',
            type: 'أسبوعي (5 أيام)',
            days: 5,
            price: config.fiveDays,
            setPrice: (double p) => setState(
              () => _pricingMatrix[key] = config.copyWith(fiveDays: p),
            ),
          ),
          (
            name: 'اشتراك أسبوعين خلال الشهر',
            type: 'نصف شهري (10 أيام)',
            days: 10,
            price: config.tenDays,
            setPrice: (double p) => setState(
              () => _pricingMatrix[key] = config.copyWith(tenDays: p),
            ),
          ),
          (
            name: 'اشتراك شهري كامل',
            type: 'شهري (22 يوم)',
            days: 22,
            price: config.monthly,
            setPrice: (double p) => setState(
              () => _pricingMatrix[key] = config.copyWith(monthly: p),
            ),
          ),
          (
            name: 'اشتراك ربع سنوي مميز',
            type: '3 شهور (66 يوم)',
            days: 66,
            price: config.threeMonths,
            setPrice: (double p) => setState(
              () => _pricingMatrix[key] = config.copyWith(threeMonths: p),
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ضبط أسعار الباقات والاشتراكات المخصصة للرحلة:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                const Text('اختر شريحة المسار للضبط: '),
                const SizedBox(width: AppSpacing.small),
                DropdownButton<String>(
                  value: '${currentSegment.from.id}_${currentSegment.to.id}',
                  items: segments.map((seg) {
                    return DropdownMenuItem(
                      value: '${seg.from.id}_${seg.to.id}',
                      child: Text(
                        '${seg.from.name} ← ${seg.to.name} (التذكرة: ${(_pricingMatrix['${seg.from.id}_${seg.to.id}']?.oneTime ?? 15.0).toStringAsFixed(0)} ج.م)',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final parts = val.split('_');
                    final matched = segments.firstWhere(
                      (s) => s.from.id == parts[0] && s.to.id == parts[1],
                    );
                    setSubState(() => currentSegment = matched);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.8),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.2),
              },
              border: TableBorder.all(color: scheme.outline.withAlpha(50)),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withAlpha(85),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'اسم الباقة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'نوع الباقة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'السعر الأساسي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'سعر الاشتراك',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'نسبة الخصم',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'الوفر الفعلي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...packagesList.map((pkg) {
                  final basePrice = config.oneTime * pkg.days;
                  final discountPercent = basePrice > 0
                      ? ((basePrice - pkg.price) / basePrice * 100)
                      : 0.0;
                  final savings = basePrice - pkg.price;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(pkg.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(pkg.type),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('${basePrice.toStringAsFixed(0)} ج.م'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        child: TextFormField(
                          key: ValueKey('${key}_${pkg.type}_price'),
                          initialValue: pkg.price.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          inputFormatters: FleetInputFormatters.money,
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            pkg.setPrice(parsed);
                            // Trigger setSubState to show live calculations
                            setSubState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        child: TextFormField(
                          key: ValueKey('${key}_${pkg.type}_disc'),
                          initialValue: discountPercent.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          inputFormatters: FleetInputFormatters.money,
                          decoration: const InputDecoration(suffixText: '%'),
                          onChanged: (val) {
                            final parsedDisc = double.tryParse(val) ?? 0.0;
                            final nextPrice =
                                basePrice * (1 - parsedDisc / 100);
                            pkg.setPrice(nextPrice);
                            setSubState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          '${savings.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            color: savings > 0 ? scheme.primary : scheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- STEP 7: REVIEW ---
  Widget _buildStep7Review() {
    if (_selectedRoute == null ||
        _selectedVehicle == null ||
        _selectedDriver == null) {
      return const Center(
        child: Text('البيانات غير مكتملة، يرجى مراجعة الخطوات السابقة.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مراجعة وتأكيد تفاصيل الرحلة التشغيلية:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              _buildReviewRow(
                'المسار المختار',
                _selectedRoute!.name,
                Icons.alt_route_rounded,
              ),
              const Divider(),
              _buildReviewRow(
                'المركبة ولوحة الأرقام',
                '${_selectedVehicle!.model} (${_selectedVehicle!.plateNumber})',
                Icons.airport_shuttle_rounded,
              ),
              const Divider(),
              _buildReviewRow(
                'السائق المعين',
                _selectedDriver!.name,
                Icons.person_outline_rounded,
              ),
              const Divider(),
              _buildReviewRow(
                'موعد وتاريخ انطلاق الرحلة',
                '${_dateController.text} في ${_timeController.text}',
                Icons.access_time_rounded,
              ),
              const Divider(),
              _buildReviewRow(
                'وقت الوصول المتوقع',
                _arrivalController.text,
                Icons.flag_outlined,
              ),
              const Divider(),
              _buildReviewRow(
                'السعة الاستيعابية للرحلة',
                '${_selectedVehicle!.capacity} مقعد',
                Icons.airline_seat_recline_normal,
              ),
              const Divider(),
              _buildReviewRow(
                'إجمالي نقاط الوقوف',
                '${_selectedRoute!.stations.length} محطات',
                Icons.pin_drop_outlined,
              ),
              const Divider(),
              _buildReviewRow(
                'سعر التذكرة القياسي',
                '${_priceController.text} ج.م',
                Icons.price_change_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: AppSpacing.medium),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- STEP 8: CONFIRMATION & CREATION ---
  // ignore: unused_element
  Widget _buildStep8Confirmation() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.large),
        Icon(Icons.verified_user_rounded, color: scheme.primary, size: 84),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'كل شيء جاهز للتشغيل!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.small),
        const Text(
          'عند النقر على "إنشاء وتشغيل الرحلة"، سيتم فوراً إسناد السائق والمركبة والجدول الزمني والتسعيرات وباقات الاشتراكات. وسيتم نقلك مباشرة إلى لوحة تفاصيل الرحلة لبدء تتبع الركاب والمدفوعات والمقاعد.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.large),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildFooter(ColorScheme scheme) {
    final canGoNext = _currentStep < 5;
    final canSubmit = _currentStep == 5;

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
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep -= 1),
              child: const Text('السابق'),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          const Spacer(),
          if (canGoNext)
            FilledButton(
              onPressed: _isStepValid()
                  ? () => setState(() => _currentStep += 1)
                  : null,
              child: const Text('التالي'),
            ),
          if (canSubmit)
            FilledButton(
              onPressed: _onSubmitTrip,
              child: const Text('إنشاء وتشغيل الرحلة'),
            ),
        ],
      ),
    );
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedRoute != null;
      case 1:
        return _selectedVehicle != null;
      case 2:
        return _selectedDriver != null;
      case 3:
        return _dateController.text.isNotEmpty &&
            _timeController.text.isNotEmpty &&
            _arrivalController.text.isNotEmpty;
      case 4:
        return (double.tryParse(_priceController.text.trim()) ?? 0) > 0;
      default:
        return true;
    }
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
      ticketPrice: double.tryParse(_priceController.text.trim()) ?? 0,
      currency: 'ج.م',
      customStationTimes: customStationTimesList,
    );

    final cubit = context.read<TripCreationCubit>();
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

class _TimeIndicator extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback? onTap;

  const _TimeIndicator({required this.label, required this.time, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: onTap != null
                  ? Border.all(color: scheme.primary.withAlpha(50))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded, size: 12, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentItem {
  final RouteStation from;
  final RouteStation to;

  const _SegmentItem({required this.from, required this.to});
}

class _PricingConfig {
  final double oneTime;
  final double fiveDays;
  final double tenDays;
  final double monthly;
  final double threeMonths;

  const _PricingConfig({
    required this.oneTime,
    this.fiveDays = 0,
    this.tenDays = 0,
    this.monthly = 0,
    this.threeMonths = 0,
  });

  _PricingConfig copyWith({
    double? oneTime,
    double? fiveDays,
    double? tenDays,
    double? monthly,
    double? threeMonths,
  }) {
    return _PricingConfig(
      oneTime: oneTime ?? this.oneTime,
      fiveDays: fiveDays ?? this.fiveDays,
      tenDays: tenDays ?? this.tenDays,
      monthly: monthly ?? this.monthly,
      threeMonths: threeMonths ?? this.threeMonths,
    );
  }
}
