import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';

import '../../../routes/domain/entities/operation_route.dart';
import '../../shared/domain/entities/operation_trip.dart';
import '../../shared/domain/entities/trip_pricable_package.dart';
import '../../shared/presentation/widgets/trip_fare_controllers.dart';
import '../../shared/presentation/widgets/trip_fare_fields.dart';
import '../../trip_creation/domain/entities/trip_driver_option.dart';
import '../../trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class TripCreationWizardDialog extends StatelessWidget {
  const TripCreationWizardDialog({
    super.key,
    this.prefillTrip,
    this.onOpenModule,
  });
  final OperationTrip? prefillTrip;

  /// Switches the shell to another module. Supplied so the planner can send an
  /// operator to Fleet when the driver they picked has no vehicle assigned.
  final ValueChanged<String>? onOpenModule;

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
            SnackBar(
              content: Text(
                'تم إنشاء الرحلة بنجاح',
                style: TextStyle(
                  color: context.status(AppStatusTone.success).onFill,
                ),
              ),
              backgroundColor: context.status(AppStatusTone.success).fill,
              duration: const Duration(seconds: 4),
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
          return TripCreationWizard(
            routes: state.routes.map(_parseRoute).toList(),
            drivers: state.drivers,
            packages: state.packages,
            prefillTrip: prefillTrip,
            onOpenModule: onOpenModule,
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
}

class TripCreationWizard extends StatefulWidget {
  final List<OperationRoute> routes;

  /// Drivers with the bus each one operates. There is no vehicle list: the operator
  /// picks a driver and the vehicle comes with them.
  final List<TripDriverOption> drivers;

  /// The office's own pricable packages — one fare field renders per entry.
  final List<TripPricablePackage> packages;

  final OperationTrip? prefillTrip;
  final ValueChanged<String>? onOpenModule;

  const TripCreationWizard({
    super.key,
    required this.routes,
    required this.drivers,
    required this.packages,
    this.prefillTrip,
    this.onOpenModule,
  });

  @override
  State<TripCreationWizard> createState() => _TripCreationWizardState();
}

class _TripCreationWizardState extends State<TripCreationWizard> {
  OperationRoute? _selectedRoute;
  TripDriverOption? _selectedDriver;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _arrivalController = TextEditingController();
  Map<String, int> _stopWaits = {};
  final Map<String, String> _customArrivals = {};
  final Map<String, String> _customDepartures = {};

  /// The ONE fare configured for this trip: the ticket price plus one price
  /// per the office's own packages, derived from it. Applied to every
  /// boarding -> dropoff pair on submit, so `trip_pricing` is fully
  /// populated the moment the trip exists and the Client app never has to
  /// fall back to a guessed price.
  late final _fare = TripFareControllers(widget.packages);

  /// Driver/vehicle ids already committed to an overlapping trip for the
  /// currently chosen date/departure/arrival, keyed to the conflicting row so
  /// the picker can explain *why* — refreshed from the server on every
  /// schedule change. The exclusion constraints in the database remain the
  /// final word; this only keeps the operator from picking a resource that is
  /// already known to fail before they submit.
  Map<String, Map<String, dynamic>> _busyDriverInfo = {};
  Map<String, Map<String, dynamic>> _busyVehicleInfo = {};
  bool _checkingAvailability = false;
  int _availabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    _applyDefaultSchedule();
    final prefill = widget.prefillTrip;
    if (prefill != null) {
      _selectedRoute = widget.routes
          .where((r) => r.id == prefill.routeId)
          .firstOrNull;

      _selectedDriver = widget.drivers
          .where((d) => d.id == prefill.driverId)
          .firstOrNull;
      _timeController.text = prefill.departure;
      _arrivalController.text = prefill.arrival;
      _dateController.text = prefill.date;
      if (prefill.ticketPrice > 0) {
        _fare.oneTime.text = TripFareControllers.formatFare(
          prefill.ticketPrice,
        );
        _fare.syncPricesFromBase();
      }
      if (_selectedRoute != null) _initializeWizardData();
    }
    _refreshAvailability();
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTokens.radiusLarge),
          topRight: Radius.circular(AppTokens.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primary.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radius),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: scheme.onPrimary,
              size: 28,
            ),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
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
          AnimatedSwitcher(
            duration: AppTokens.motionBase,
            child: _PlannerReadinessPill(
              key: ValueKey(_isTripReady()),
              ready: _isTripReady(),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'إغلاق',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTokens.radiusLarge),
          bottomRight: Radius.circular(AppTokens.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final message = AnimatedSwitcher(
            duration: AppTokens.motionBase,
            child: Text(
              ready ? 'كل شيء جاهز للتشغيل' : _readinessMessage(),
              key: ValueKey(ready ? 'ready' : _readinessMessage()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ready ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: ready ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
          final actions = [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            OutlinedButton.icon(
              onPressed: _resetPlanner,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('إعادة ضبط'),
            ),
            FilledButton.icon(
              onPressed: ready ? _onSubmitTrip : null,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('إنشاء الرحلة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
            ),
          ];

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            );
          }

          return Row(
            children: [
              actions[0],
              const SizedBox(width: AppSpacing.small),
              actions[1],
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: message,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              actions[2],
            ],
          );
        },
      ),
    );
  }

  /// Route → Driver → (derived) Vehicle.
  ///
  /// The vehicle card sits below the driver, is never a picker, and is marked as
  /// system-derived rather than as a step the operator completes — which is why it
  /// carries no completion tick of its own.
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
          title: 'السائق',
          icon: Icons.person_outline_rounded,
          done: _selectedDriver != null,
          child: _buildDriverPicker(),
        ),
        const SizedBox(height: AppSpacing.medium),
        _AssignedVehicleCard(
          driver: _selectedDriver,
          busyTrip: _assignedVehicleConflict,
          onAssignVehicle: _openFleetAssignment,
        ),
      ],
    );
  }

  /// The conflicting trip already holding this driver's bus, if any. Read through the
  /// driver rather than from a vehicle the operator chose, because the bus is only ever
  /// reached through the driver now.
  Map<String, dynamic>? get _assignedVehicleConflict {
    final vehicleId = _selectedDriver?.assignedVehicle?.id;
    return vehicleId == null ? null : _busyVehicleInfo[vehicleId];
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

          isExpanded: true,
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
            _refreshAvailability();
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

  /// The only resource choice in this planner.
  ///
  /// A driver is offered as busy when *either* they or their bus is already committed
  /// to an overlapping trip — the two are one resource once they are paired, and the
  /// operator has no way to swap one without the other from here.
  Widget _buildDriverPicker() {
    final scheme = Theme.of(context).colorScheme;
    final drivers = widget.drivers;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedDriver?.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'اختر السائق',
            prefixIcon: const Icon(Icons.badge_outlined),
            suffixIcon: _checkingAvailability
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: drivers.map((driver) {
            final conflict = _driverConflict(driver);

            return DropdownMenuItem(
              value: driver.id,
              enabled: conflict == null,
              child: Text(
                _driverOptionLabel(driver, conflict),
                overflow: TextOverflow.ellipsis,
                style: conflict == null && driver.isSchedulable
                    ? null
                    : TextStyle(color: scheme.onSurfaceVariant.withAlpha(180)),
              ),
            );
          }).toList(),
          onChanged: (id) {
            final driver = drivers
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
            trailing: 'نشط',
            icon: Icons.person_outline_rounded,
          ),
        ],
        if (_busyDriverInfo.isNotEmpty || _busyVehicleInfo.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            'السائقون المشغولون لديهم — أو لدى سيارتهم — رحلة أخرى قريبة من هذا '
            'التوقيت (مع احتساب نصف ساعة للاستعداد بين الرحلات).',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  /// The overlapping trip that makes this driver unpickable — theirs, or their bus's.
  Map<String, dynamic>? _driverConflict(TripDriverOption driver) {
    return _busyDriverInfo[driver.id] ??
        (driver.assignedVehicle == null
            ? null
            : _busyVehicleInfo[driver.assignedVehicle!.id]);
  }

  String _driverOptionLabel(
    TripDriverOption driver,
    Map<String, dynamic>? conflict,
  ) {
    if (!driver.hasVehicle) return '${driver.name} • بدون سيارة مخصصة';
    final vehicle = driver.assignedVehicle!;
    if (!vehicle.isSchedulable) {
      return '${driver.name} • سيارته ${vehicle.plateNumber} غير متاحة';
    }
    if (conflict != null) {
      return '${driver.name} • مشغول (${_conflictLabel(conflict)})';
    }
    return '${driver.name} • ${vehicle.plateNumber} • ${vehicle.capacity} مقعد';
  }

  /// Sends the operator to Fleet to pair the driver with a bus. The planner closes
  /// first: coming back to a half-filled form whose driver list is now stale would be
  /// worse than restarting it with correct data.
  void _openFleetAssignment() {
    Navigator.of(context).pop();
    widget.onOpenModule?.call(DashboardRoutes.assignments);
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

          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                _PlannerStatusChip(label: 'مسار', done: _selectedRoute != null),
                _PlannerStatusChip(
                  label: 'سائق',
                  done: _selectedDriver != null,
                ),

                _PlannerStatusChip(
                  label: 'سيارة',
                  done: _selectedDriver?.isSchedulable ?? false,
                ),
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
            _InteractiveTimeTile(
              label: 'تاريخ الرحلة',
              value: _dateController.text,
              icon: Icons.calendar_month_rounded,
              onTap: _pickTripDate,
              placeholder: 'اختر التاريخ',
            ),
            _InteractiveTimeTile(
              label: 'وقت الانطلاق',
              value: _timeController.text,
              icon: Icons.access_time_filled_rounded,
              onTap: _pickDepartureTime,
              placeholder: 'اختر الوقت',
            ),
            _InteractiveTimeTile(
              label: 'وقت الوصول',
              value: _arrivalController.text,
              icon: Icons.flag_circle_rounded,
              onTap: _pickArrivalTime,
              placeholder: 'اختر الوقت',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            ActionChip(
              avatar: const Icon(Icons.today_rounded, size: 18),
              label: const Text('اليوم'),
              onPressed: () => _setDateOffset(0),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_rounded, size: 18),
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
              onPressed: () {
                setState(_syncArrivalFromRoute);
                _refreshAvailability();
              },
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
        TripFareFields(controllers: _fare, onChanged: () => setState(() {})),
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

  /// A driver with no bus — or a bus that is out of service — is not a complete plan.
  /// The submit button stays disabled rather than letting the operator discover it from
  /// a server refusal.
  bool _isTripReady() {
    return _selectedRoute != null &&
        (_selectedDriver?.isSchedulable ?? false) &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _arrivalController.text.isNotEmpty &&
        _fare.isValid;
  }

  String _readinessMessage() {
    final driver = _selectedDriver;
    if (driver != null && !driver.hasVehicle) {
      return 'هذا السائق غير مرتبط بسيارة حالياً — عيّن له سيارة أولاً.';
    }
    if (driver != null && !driver.isSchedulable) {
      return 'السيارة المخصصة لهذا السائق غير متاحة للتشغيل حالياً.';
    }
    final missing = <String>[
      if (_selectedRoute == null) 'المسار',
      if (driver == null) 'السائق',
      if (_dateController.text.isEmpty ||
          _timeController.text.isEmpty ||
          _arrivalController.text.isEmpty)
        'الموعد',
      if (!_fare.isValid) 'السعر',
    ];
    return missing.isEmpty ? 'جاهز' : 'المتبقي: ${missing.join('، ')}';
  }

  String _tripSummaryLine() {
    final vehicle = _selectedDriver?.assignedVehicle;
    return '${_selectedRoute?.name ?? '-'} • ${_selectedDriver?.name ?? '-'} • '
        '${vehicle?.plateNumber ?? '-'} • ${_dateController.text} '
        '${_timeController.text}';
  }

  void _resetPlanner() {
    setState(() {
      _selectedRoute = null;
      _selectedDriver = null;
      _stopWaits = {};
      _customArrivals.clear();
      _customDepartures.clear();
      _fare.clear();
      _applyDefaultSchedule();
    });
    _refreshAvailability();
  }

  /// Re-queries which drivers/vehicles are already committed to an
  /// overlapping trip for the current date/departure/arrival, so the pickers
  /// below can stop offering them. Safe to call as often as the schedule
  /// changes: stale in-flight responses are dropped via [_availabilityRequestId],
  /// and a failed lookup just leaves the last-known availability in place
  /// (fails open — the server's exclusion constraints still guard submission).
  Future<void> _refreshAvailability() async {
    final date = _dateController.text;
    final departure = _timeController.text;
    final arrival = _arrivalController.text;
    if (date.isEmpty || departure.isEmpty) return;

    final requestId = ++_availabilityRequestId;
    setState(() => _checkingAvailability = true);
    try {
      final conflicts = await context
          .read<TripCreationCubit>()
          .getResourceConflicts(
            date: date,
            departureTime: departure,
            arrivalTime: arrival,
          );
      if (!mounted || requestId != _availabilityRequestId) return;

      final busyDrivers = <String, Map<String, dynamic>>{};
      final busyVehicles = <String, Map<String, dynamic>>{};
      for (final row in conflicts) {
        final driverId = row['driver_id'] as String?;
        final vehicleId = row['vehicle_id'] as String?;
        if (driverId != null) busyDrivers[driverId] = row;
        if (vehicleId != null) busyVehicles[vehicleId] = row;
      }

      setState(() {
        _busyDriverInfo = busyDrivers;
        _busyVehicleInfo = busyVehicles;
        _checkingAvailability = false;
      });

      final chosen = _selectedDriver;
      if (chosen == null) return;

      final vehicleId = chosen.assignedVehicle?.id;
      if (busyDrivers.containsKey(chosen.id)) {
        setState(() => _selectedDriver = null);
        _showAvailabilityNotice(
          'السائق "${chosen.name}" أصبح غير متاح لهذا التوقيت — اختر سائقاً آخر.',
        );
      } else if (vehicleId != null && busyVehicles.containsKey(vehicleId)) {
        setState(() => _selectedDriver = null);
        _showAvailabilityNotice(
          'السيارة المخصصة للسائق "${chosen.name}" '
          '(${chosen.assignedVehicle!.plateNumber}) أصبحت مرتبطة برحلة أخرى في هذا '
          'التوقيت — اختر سائقاً آخر أو غيّر الموعد.',
        );
      }
    } catch (_) {
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() => _checkingAvailability = false);
    }
  }

  void _showAvailabilityNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  /// "08:00" from a trip's conflicting `trip_code`/`departure_time`, for the
  /// disabled-picker explanation.
  String _conflictLabel(Map<String, dynamic> conflict) {
    final departure = conflict['departure_time'] as String? ?? '';
    final hhmm = departure.length >= 5 ? departure.substring(0, 5) : departure;
    final code = conflict['trip_code'] as String?;
    return code != null && code.isNotEmpty ? '$code • $hhmm' : hhmm;
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
    _refreshAvailability();
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
    _refreshAvailability();
  }

  Future<void> _pickArrivalTime() async {
    final initial = _timeOfDayFromText(_arrivalController.text);
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    setState(() {
      _arrivalController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    });
    _refreshAvailability();
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
    _refreshAvailability();
  }

  void _setNextHourDeparture() {
    final now = DateTime.now().add(const Duration(hours: 1));
    final next = DateTime(now.year, now.month, now.day, now.hour);
    setState(() {
      _dateController.text = _formatDate(next);
      _timeController.text = '${next.hour.toString().padLeft(2, '0')}:00:00';
      _syncArrivalFromRoute();
    });
    _refreshAvailability();
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
      date: _dateController.text,
      departure: _timeController.text,
      arrival: _arrivalController.text,
      ticketPrice: _fare.baseFare,
      packagePrices: _fare.packagePrices,
      currency: 'ج.م',
      customStationTimes: customStationTimesList,
    );

    final cubit = context.read<TripCreationCubit>();

    final created = await cubit.submitTrip(input, const [], widget.packages);

    if (mounted && created != null) {
      Navigator.of(context).pop();
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
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: done
              ? scheme.primary.withAlpha(40)
              : scheme.outline.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: AnimatedContainer(
          duration: AppTokens.motionBase,
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: done ? scheme.primary : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: done
                            ? scheme.primaryContainer.withAlpha(100)
                            : scheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: done ? scheme.primary : scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: AppTokens.motionBase,
                      child: Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        key: ValueKey(done),
                        color: done
                            ? scheme.primary
                            : scheme.outline.withAlpha(100),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannerReadinessPill extends StatelessWidget {
  final bool ready;

  const _PlannerReadinessPill({super.key, required this.ready});

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

class _InteractiveTimeTile extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveTimeTile({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      // A minimum, not a fixed lane: at 1.3x+ text scale the Arabic label is wider
      // than 220 and a hard width clipped it. The tiles sit in a Wrap, so letting
      // one grow past the minimum costs nothing but a reflow.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: hasValue
                  ? scheme.primaryContainer.withAlpha(30)
                  : scheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: hasValue
                    ? scheme.primary.withAlpha(80)
                    : scheme.outline.withAlpha(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: hasValue
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  hasValue ? value : placeholder,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: hasValue
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant.withAlpha(150),
                    fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

/// The vehicle the system chose, shown as information rather than as a field.
///
/// It is styled deliberately unlike the pickers above it — a tinted, outlined panel
/// with a "derived automatically" line instead of a form control — so that at a glance
/// the operator can tell what they chose (route, driver) from what the system chose
/// (this bus). Nothing in here is tappable except the escape hatch for a driver who has
/// no bus at all.
class _AssignedVehicleCard extends StatelessWidget {
  const _AssignedVehicleCard({
    required this.driver,
    required this.busyTrip,
    required this.onAssignVehicle,
  });

  final TripDriverOption? driver;

  /// The overlapping trip already holding this bus, if the schedule picked one that is
  /// out. Explained here rather than only on submit, because the operator's fix is to
  /// change the time or the driver — both of which are on this screen.
  final Map<String, dynamic>? busyTrip;

  final VoidCallback onAssignVehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final current = driver;
    final vehicle = current?.assignedVehicle;

    final (Color tint, Color line, IconData icon) = switch (current) {
      null => (
        scheme.surfaceContainerHighest,
        scheme.outline,
        Icons.directions_bus_outlined,
      ),
      _ when vehicle == null => (
        scheme.errorContainer,
        scheme.error,
        Icons.report_problem_outlined,
      ),
      _ when !vehicle.isSchedulable || busyTrip != null => (
        scheme.tertiaryContainer,
        scheme.tertiary,
        Icons.build_circle_outlined,
      ),
      _ => (
        scheme.primaryContainer,
        scheme.primary,
        Icons.airport_shuttle_rounded,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: line.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: line, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tint.withAlpha(100),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Icon(icon, color: line, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        'السيارة المخصصة للسائق',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.lock_rounded,
                      size: 18,
                      color: scheme.outline.withAlpha(150),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: tint.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(color: line.withAlpha(40)),
                  ),
                  child: _body(context, current, vehicle, line),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    TripDriverOption? current,
    AssignedVehicle? vehicle,
    Color line,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (current == null) {
      return Text(
        'اختر السائق أولاً وستظهر هنا السيارة المخصصة له تلقائياً.',
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    if (vehicle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'هذا السائق غير مرتبط بسيارة حالياً',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: line,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'لا يمكن إنشاء رحلة لسائق بدون سيارة مخصصة. اربطه بسيارة من إدارة '
            'الأسطول ثم أعد فتح مخطط الرحلة.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: onAssignVehicle,
              icon: const Icon(Icons.link_rounded),
              label: const Text('تعيين سيارة للسائق'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vehicle.displayName,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.small),

        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            _VehicleFact(label: 'رقم اللوحة', value: vehicle.plateNumber),
            _VehicleFact(label: 'عدد المقاعد', value: '${vehicle.capacity}'),
            if (vehicle.vehicleCode.isNotEmpty)
              _VehicleFact(label: 'كود المركبة', value: vehicle.vehicleCode),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        if (!vehicle.isSchedulable)
          _VehicleNotice(
            icon: Icons.build_circle_outlined,
            color: line,
            message:
                'هذه السيارة غير متاحة للتشغيل حالياً. أعدها إلى حالة "نشطة" من '
                'إدارة الأسطول أو عيّن للسائق سيارة أخرى.',
          )
        else if (busyTrip != null)
          _VehicleNotice(
            icon: Icons.event_busy_outlined,
            color: line,
            message:
                'هذه السيارة مرتبطة برحلة أخرى تتداخل مع هذا التوقيت. غيّر الموعد '
                'أو اختر سائقاً آخر.',
          )
        else
          _VehicleNotice(
            icon: Icons.check_circle_outline_rounded,
            color: line,
            message:
                'سيتم استخدام السيارة المخصصة للسائق تلقائياً، وسيتم بناء مقاعد '
                'الرحلة من تخطيط مقاعدها.',
          ),
      ],
    );
  }
}

class _VehicleFact extends StatelessWidget {
  const _VehicleFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(160),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _VehicleNotice extends StatelessWidget {
  const _VehicleNotice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
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
