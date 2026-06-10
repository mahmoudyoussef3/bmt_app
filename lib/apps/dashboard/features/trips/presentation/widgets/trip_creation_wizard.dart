import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../routes/domain/entities/operation_route.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../cubit/trips_cubit.dart';

class TripCreationWizard extends StatefulWidget {
  final List<OperationRoute> routes;
  final List<Vehicle> vehicles;
  final List<Driver> drivers;

  const TripCreationWizard({
    super.key,
    required this.routes,
    required this.vehicles,
    required this.drivers,
  });

  @override
  State<TripCreationWizard> createState() => _TripCreationWizardState();
}

class _TripCreationWizardState extends State<TripCreationWizard> {
  int _currentStep = 0;

  // Selected values
  OperationRoute? _selectedRoute;
  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;

  // Schedule values
  final _dateController = TextEditingController(text: '٨ يونيو ٢٠٢٦');
  final _timeController = TextEditingController(text: '٠٧:٠٠');
  Map<String, int> _stopWaits = {}; // stationId -> wait minutes

  // Pricing values
  // Matrix format: fromPointId_toPointId -> prices
  Map<String, _PricingConfig> _pricingMatrix = {};

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _initializeWizardData() {
    if (_selectedRoute == null) return;
    final points = _selectedRoute!.stations;

    // Initialize stop wait durations (default 2 mins)
    _stopWaits = {
      for (var st in points) st.id: 2,
    };

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
          fiveDays: baseOneTime * 5 * 0.9,      // 10% discount
          tenDays: baseOneTime * 10 * 0.85,    // 15% discount
          monthly: baseOneTime * 22 * 0.8,     // 20% discount
          threeMonths: baseOneTime * 66 * 0.75, // 25% discount
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: SizedBox(
        width: 1100,
        height: 780,
        child: Column(
          children: [
            // Header
            _buildHeader(scheme),
            // Step Indicator Progress Bar
            _buildStepProgressBar(scheme),
            // Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: _buildStepContent(),
              ),
            ),
            // Footer Navigation
            _buildFooter(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final stepTitles = [
      'اختيار المسار',
      'اختيار المركبة',
      'اختيار السائق',
      'جدولة الرحلة والمحطات',
      'إدارة تسعير الرحلة',
      'اشتراكات وباقات الرحلة',
      'مراجعة الرحلة وتأكيدها',
      'إنشاء الرحلة والتشغيل',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.radiusLarge),
          topRight: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(
          bottom: BorderSide(color: scheme.outline.withAlpha(50)),
        ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الخطوة ${_currentStep + 1} من 8: ${stepTitles[_currentStep]}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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

  Widget _buildStepProgressBar(ColorScheme scheme) {
    return Container(
      height: 4,
      width: double.infinity,
      color: scheme.outline.withAlpha(30),
      child: Row(
        children: List.generate(8, (index) {
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
        return _buildStep6PackagesPricing();
      case 6:
        return _buildStep7Review();
      case 7:
        return _buildStep8Confirmation();
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.routes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
                  color: selected ? scheme.primaryContainer.withAlpha(40) : scheme.surface,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline.withAlpha(60),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              Icon(Icons.location_on_outlined, size: 14, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text('${route.stations.length} محطات', style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(width: AppSpacing.medium),
                              Icon(Icons.directions_car_outlined, size: 14, color: scheme.secondary),
                              const SizedBox(width: 4),
                              Text(route.distance, style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(width: AppSpacing.medium),
                              Icon(Icons.access_time, size: 14, color: scheme.tertiary),
                              const SizedBox(width: 4),
                              Text(route.duration, style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: scheme.primary, size: 28),
                  ],
                ),
              ),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.vehicles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
                  if (_selectedDriver != null && _selectedDriver!.currentVehicle != vehicle.plateNumber) {
                    _selectedDriver = null;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? scheme.primaryContainer.withAlpha(40) : scheme.surface,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline.withAlpha(60),
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: selected ? scheme.primary : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              StatusChip(label: vehicle.status.label),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text('رقم اللوحة: ${vehicle.plateNumber}', style: Theme.of(context).textTheme.bodyMedium),
                          Text('النوع: ${vehicle.type}', style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.airline_seat_recline_normal, size: 16, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text('السعة: ${vehicle.capacity} مقعد', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: scheme.primary, size: 28),
                  ],
                ),
              ),
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
        .where((d) => d.status == DriverStatus.active)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر سائقاً متاحاً لتشغيل الرحلة:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableDrivers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
                  color: selected ? scheme.primaryContainer.withAlpha(40) : scheme.surface,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline.withAlpha(60),
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
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected ? scheme.primary : null,
                            ),
                          ),
                          Text('رقم الهاتف: ${driver.phone}', style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Text(
                            'المركبة الحالية: ${driver.currentVehicle}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'آخر رحلة: ${driver.currentRoute}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: scheme.primary, size: 28),
                  ],
                ),
              ),
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
    if (startTimeParts.length == 2) {
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ الرحلة',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'وقت الانطلاق الأساسي',
                  prefixIcon: Icon(Icons.access_time_rounded),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ],
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

            final arrivalTime = getTimeStr(accumulatedMinutes);
            final departureTime = getTimeStr(accumulatedMinutes + wait);

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
                      child: Text('${index + 1}', style: TextStyle(color: scheme.primary)),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('النطاق: ${station.area}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    _TimeIndicator(label: 'وصول متوقع', time: index == 0 ? _timeController.text : arrivalTime),
                    const SizedBox(width: AppSpacing.medium),
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<int>(
                        initialValue: wait,
                        decoration: const InputDecoration(labelText: 'فترة الانتظار'),
                        items: [1, 2, 3, 5, 8, 10]
                            .map((m) => DropdownMenuItem(value: m, child: Text('$m دقائق')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _stopWaits[station.id] = val ?? 2;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    _TimeIndicator(label: 'تحرك متوقع', time: departureTime),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إدارة تسعير الرحلة (Matrix UI):',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'أدخل سعر التذكرة الفردية (بالجنيه المصري) لكل محطات الصعود والوصول مباشرة في الجدول أدناه:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.medium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(130),
            border: TableBorder.all(color: scheme.outline.withAlpha(50)),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withAlpha(80)),
                children: [
                  const TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('من \\ إلى', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                  ...stations.sublist(1).map(
                        (st) => TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                        child: Text(fromSt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      final config = _pricingMatrix[key] ?? _PricingConfig(oneTime: 15);

                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: TextFormField(
                            initialValue: config.oneTime.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              suffixText: 'ج.م',
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
            setPrice: (double p) => setState(() => _pricingMatrix[key] = config.copyWith(fiveDays: p)),
          ),
          (
            name: 'اشتراك أسبوعين خلال الشهر',
            type: 'نصف شهري (10 أيام)',
            days: 10,
            price: config.tenDays,
            setPrice: (double p) => setState(() => _pricingMatrix[key] = config.copyWith(tenDays: p)),
          ),
          (
            name: 'اشتراك شهري كامل',
            type: 'شهري (22 يوم)',
            days: 22,
            price: config.monthly,
            setPrice: (double p) => setState(() => _pricingMatrix[key] = config.copyWith(monthly: p)),
          ),
          (
            name: 'اشتراك ربع سنوي مميز',
            type: '3 شهور (66 يوم)',
            days: 66,
            price: config.threeMonths,
            setPrice: (double p) => setState(() => _pricingMatrix[key] = config.copyWith(threeMonths: p)),
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
                      child: Text('${seg.from.name} ← ${seg.to.name} (التذكرة: ${(_pricingMatrix['${seg.from.id}_${seg.to.id}']?.oneTime ?? 15.0).toStringAsFixed(0)} ج.م)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final parts = val.split('_');
                    final matched = segments.firstWhere((s) => s.from.id == parts[0] && s.to.id == parts[1]);
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
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withAlpha(85)),
                  children: const [
                    Padding(padding: EdgeInsets.all(10), child: Text('اسم الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('نوع الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('السعر الأساسي', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('سعر الاشتراك', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('نسبة الخصم', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(10), child: Text('الوفر الفعلي', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ...packagesList.map((pkg) {
                  final basePrice = config.oneTime * pkg.days;
                  final discountPercent = basePrice > 0 ? ((basePrice - pkg.price) / basePrice * 100) : 0.0;
                  final savings = basePrice - pkg.price;

                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: Text(pkg.name)),
                      Padding(padding: const EdgeInsets.all(10), child: Text(pkg.type)),
                      Padding(padding: const EdgeInsets.all(10), child: Text('${basePrice.toStringAsFixed(0)} ج.م')),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: TextFormField(
                          key: ValueKey('${key}_${pkg.type}_price'),
                          initialValue: pkg.price.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            pkg.setPrice(parsed);
                            // Trigger setSubState to show live calculations
                            setSubState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: TextFormField(
                          key: ValueKey('${key}_${pkg.type}_disc'),
                          initialValue: discountPercent.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: '%'),
                          onChanged: (val) {
                            final parsedDisc = double.tryParse(val) ?? 0.0;
                            final nextPrice = basePrice * (1 - parsedDisc / 100);
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
    if (_selectedRoute == null || _selectedVehicle == null || _selectedDriver == null) {
      return const Center(child: Text('البيانات غير مكتملة، يرجى مراجعة الخطوات السابقة.'));
    }

    final pricingList = _pricingMatrix.entries.where((e) {
      final parts = e.key.split('_');
      final from = _selectedRoute!.stations.firstWhere((st) => st.id == parts[0]);
      final to = _selectedRoute!.stations.firstWhere((st) => st.id == parts[1]);
      return from.order < to.order;
    }).toList();

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
              _buildReviewRow('المسار المختار', _selectedRoute!.name, Icons.alt_route_rounded),
              const Divider(),
              _buildReviewRow('المركبة ولوحة الأرقام', '${_selectedVehicle!.model} (${_selectedVehicle!.plateNumber})', Icons.airport_shuttle_rounded),
              const Divider(),
              _buildReviewRow('السائق المعين', _selectedDriver!.name, Icons.person_outline_rounded),
              const Divider(),
              _buildReviewRow('موعد وتاريخ انطلاق الرحلة', '${_dateController.text} في ${_timeController.text}', Icons.access_time_rounded),
              const Divider(),
              _buildReviewRow('السعة الاستيعابية للرحلة', '${_selectedVehicle!.capacity} مقعد', Icons.airline_seat_recline_normal),
              const Divider(),
              _buildReviewRow('إجمالي نقاط الوقوف', '${_selectedRoute!.stations.length} محطات', Icons.pin_drop_outlined),
              const Divider(),
              _buildReviewRow('عدد تسعيرات الشرائح التي تم إعدادها', '${pricingList.length} شريحة مسار', Icons.price_change_outlined),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildFooter(ColorScheme scheme) {
    final canGoNext = _currentStep < 7;
    final canSubmit = _currentStep == 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTokens.radiusLarge),
          bottomRight: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(
          top: BorderSide(color: scheme.outline.withAlpha(50)),
        ),
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
        return _dateController.text.isNotEmpty && _timeController.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _onSubmitTrip() async {
    final input = CreateTripInput(
      route: _selectedRoute!.name,
      driver: _selectedDriver!.name,
      vehicle: _selectedVehicle!.plateNumber,
      date: _dateController.text,
      departure: _timeController.text,
      capacity: _selectedVehicle!.capacity,
    );

    // Build the pricing configs
    final List<TripPricing> pricingList = [];
    _pricingMatrix.forEach((key, config) {
      final parts = key.split('_');
      final fromSt = _selectedRoute!.stations.firstWhere((st) => st.id == parts[0]);
      final toSt = _selectedRoute!.stations.firstWhere((st) => st.id == parts[1]);

      pricingList.add(TripPricing(
        id: '', // Generated by repository
        tripId: '', // Filled during creation
        fromPointId: fromSt.id,
        toPointId: toSt.id,
        fromPointName: fromSt.name,
        toPointName: toSt.name,
        fromPointOrder: fromSt.order,
        toPointOrder: toSt.order,
        oneTimePrice: config.oneTime,
        fiveDaysPrice: config.fiveDays,
        tenDaysPrice: config.tenDays,
        monthlyPrice: config.monthly,
        threeMonthsPrice: config.threeMonths,
        currency: 'ج.م',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });

    final cubit = context.read<TripsCubit>();
    final created = await cubit.createTripWithPricing(input, pricingList);

    if (mounted && created != null) {
      Navigator.of(context).pop(); // Close wizard dialog
    }
  }
}

class _TimeIndicator extends StatelessWidget {
  final String label;
  final String time;

  const _TimeIndicator({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Text(
            time,
            style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
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
