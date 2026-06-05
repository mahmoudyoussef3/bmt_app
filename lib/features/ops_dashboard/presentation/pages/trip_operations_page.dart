import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';

class _TripItem {
  final String id;
  String route;
  String departureTime;
  String driver;
  int passengerCount;
  int maxSeats;
  String status; // قادمة, جارية, مكتملة, ملغاة
  final List<String> passengers;

  _TripItem({
    required this.id,
    required this.route,
    required this.departureTime,
    required this.driver,
    required this.passengerCount,
    required this.maxSeats,
    required this.status,
    required this.passengers,
  });

  double get fillPercentage => passengerCount / maxSeats;
}

class TripOperationsPage extends StatefulWidget {
  const TripOperationsPage({super.key});

  @override
  State<TripOperationsPage> createState() => _TripOperationsPageState();
}

class _TripOperationsPageState extends State<TripOperationsPage> {
  // Mock dataset of trips
  final List<_TripItem> _trips = [
    _TripItem(
      id: 'TR-224',
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      driver: 'محمد أحمد',
      passengerCount: 10,
      maxSeats: 12,
      status: 'قادمة',
      passengers: ['عمر فاروق', 'سارة أحمد', 'شريف علي', 'نهى محمود', 'رنا يوسف', 'أحمد كمال', 'خالد يحيى', 'منى حسن', 'كريم محمد', 'هاني صلاح'],
    ),
    _TripItem(
      id: 'TR-221',
      route: 'بنها ← مدينة نصر',
      departureTime: '08:45 ص',
      driver: 'كريم حسن',
      passengerCount: 12,
      maxSeats: 12,
      status: 'جارية',
      passengers: ['يوسف شريف', 'نادين خالد', 'خالد محمود', 'ياسمين علي', 'منى شريف', 'حسام ناصر', 'طارق محمد', 'محمود مصطفى', 'شادي أيمن', 'علا سعيد', 'مروة أحمد', 'سعد مرسي'],
    ),
    _TripItem(
      id: 'TR-223',
      route: 'بنها ← المهندسين',
      departureTime: '09:00 ص',
      driver: 'مصطفى علي',
      passengerCount: 8,
      maxSeats: 12,
      status: 'قادمة',
      passengers: ['أحمد علي', 'منى حسن', 'طارق محمد', 'سامح محمود', 'خالد كمال', 'رانيا سعد', 'سارة حسن', 'فادي سمير'],
    ),
    _TripItem(
      id: 'TR-220',
      route: 'بنها ← أكتوبر',
      departureTime: '07:30 ص',
      driver: 'أحمد سعيد',
      passengerCount: 12,
      maxSeats: 12,
      status: 'مكتملة',
      passengers: ['نادر أحمد', 'جمال سعيد', 'أمل مرسي', 'إبراهيم علي', 'هالة محمد', 'سلوى محمود', 'تامر خالد', 'عمر مجدي', 'ماجدة يوسف', 'وليد حسن', 'حنان مصطفى', 'أمير أشرف'],
    ),
    _TripItem(
      id: 'TR-218',
      route: 'بنها ← المعادي',
      departureTime: '07:15 ص',
      driver: 'سعد مرسي',
      passengerCount: 0,
      maxSeats: 12,
      status: 'ملغاة',
      passengers: [],
    ),
  ];

  final List<String> _availableDrivers = ['محمد أحمد', 'كريم حسن', 'مصطفى علي', 'أحمد سعيد', 'سعد مرسي', 'هاني صلاح', 'حسين عادل', 'إيهاب طاهر'];

  void _showActionToast(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(label),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قادمة':
        return Colors.blueGrey.shade400;
      case 'جارية':
        return Colors.blue.shade400;
      case 'مكتملة':
        return Colors.green.shade400;
      case 'ملغاة':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  // Summary Metrics calculations
  int get _totalTripsCount => _trips.length;
  int get _completedTripsCount => _trips.where((t) => t.status == 'مكتملة').length;
  int get _activeTripsCount => _trips.where((t) => t.status == 'جارية').length;

  // Operational Action: Edit Trip details
  void _editTrip(_TripItem trip) {
    final routeCtrl = TextEditingController(text: trip.route);
    final timeCtrl = TextEditingController(text: trip.departureTime);

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل الرحلة ${trip.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: routeCtrl,
                  decoration: const InputDecoration(labelText: 'مسار الرحلة'),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'وقت الانطلاق'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    trip.route = routeCtrl.text;
                    trip.departureTime = timeCtrl.text;
                  });
                  Navigator.pop(context);
                  _showActionToast('تم تعديل بيانات الرحلة بنجاح');
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Operational Action: Change Driver
  void _changeDriver(_TripItem trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تغيير سائق الرحلة ${trip.id}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableDrivers.length,
                itemBuilder: (context, i) {
                  final driver = _availableDrivers[i];
                  final bool isCurrent = trip.driver == driver;
                  return ListTile(
                    title: Text(
                      driver,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      setState(() => trip.driver = driver);
                      Navigator.pop(context);
                      _showActionToast('تم تعيين السائق $driver للرحلة ${trip.id}');
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Operational Action: Cancel Trip
  void _cancelTrip(_TripItem trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إلغاء الرحلة ${trip.id}'),
            content: const Text('هل أنت متأكد من رغبتك في إلغاء هذه الرحلة؟ هذا الإجراء سيغير حالتها وسيتم إشعار الركاب.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                onPressed: () {
                  setState(() {
                    trip.status = 'ملغاة';
                    trip.passengerCount = 0;
                  });
                  Navigator.pop(context);
                  _showActionToast('تم إلغاء الرحلة وإشعار الركاب بنجاح');
                },
                child: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Operational Action: Show Passengers list
  void _showPassengers(_TripItem trip) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ركاب الرحلة ${trip.id}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    StatusChip(
                      label: '${trip.passengerCount} / ${trip.maxSeats} راكب',
                      color: scheme.primary,
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.large),
                Expanded(
                  child: trip.passengers.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد ركاب مسجلين في هذه الرحلة حالياً',
                            style: TextStyle(color: scheme.onSurface.withOpacity(0.45)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: trip.passengers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final passenger = trip.passengers[i];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: scheme.primary.withOpacity(0.12),
                                child: Text(
                                  passenger[0],
                                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              title: Text(passenger, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                                onPressed: () => _showActionToast('الاتصال بالعميل $passenger'),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة عمليات الرحلات'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SUMMARY HEADER METRICS
                  _buildSummaryHeader(context, scheme),
                  const SizedBox(height: AppSpacing.large),

                  // LIST/GRID HEADER TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رحلات اليوم النشطة (${_trips.length})',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                      Text(
                        'إدارة العمليات وتحديث السائقين مباشرة',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // RESPONSIVE GRID / LIST BUILDER
                  Expanded(
                    child: _buildTripsGrid(w, scheme),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Summary Metrics Header Widget
  Widget _buildSummaryHeader(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricItem(context, 'رحلات اليوم', _totalTripsCount.toString(), Colors.blue),
          _metricDivider(scheme),
          _metricItem(context, 'رحلات جارية', _activeTripsCount.toString(), Colors.orange),
          _metricDivider(scheme),
          _metricItem(context, 'رحلات مكتملة', _completedTripsCount.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _metricDivider(ColorScheme scheme) {
    return Container(
      width: 1,
      height: 40,
      color: scheme.outline.withOpacity(0.18),
    );
  }

  Widget _metricItem(BuildContext context, String label, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Responsive Grid Builder
  Widget _buildTripsGrid(double width, ColorScheme scheme) {
    int crossAxisCount = 1;
    if (width >= 1024) {
      crossAxisCount = 3;
    } else if (width >= 640) {
      crossAxisCount = 2;
    }

    final double childAspectRatio = width >= 1024
        ? 1.5
        : (width >= 640 ? 1.6 : 1.7);

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _trips.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final t = _trips[index];
        final statusColor = _getStatusColor(t.status);
        final bool isFull = t.fillPercentage >= 1.0;
        final Color progressColor = isFull ? Colors.red.shade400 : Colors.green.shade400;

        return Card(
          elevation: AppTokens.surfaceElevation,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top line: Route and Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t.route,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(label: t.status, color: statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),

                // Info: Time, Driver, Passengers count
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: scheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'الانطلاق: ${t.departureTime}',
                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: scheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'السائق: ${t.driver}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد الركاب: ${t.passengerCount} / ${t.maxSeats}',
                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                        ),
                        Text(
                          'نسبة الامتلاء: ${(t.fillPercentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: t.fillPercentage,
                    minHeight: 5,
                    color: progressColor,
                    backgroundColor: progressColor.withOpacity(0.15),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),

                // Bottom row: Operational Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      tooltip: 'تعديل',
                      onPressed: () => _editTrip(t),
                    ),
                    // Change Driver
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      tooltip: 'تغيير السائق',
                      onPressed: () => _changeDriver(t),
                    ),
                    // Cancel Route
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, size: 18, color: t.status == 'ملغاة' ? Colors.grey : scheme.error),
                      tooltip: 'إلغاء الرحلة',
                      onPressed: t.status == 'ملغاة' ? null : () => _cancelTrip(t),
                    ),
                    // Show Passengers
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                        ),
                      ),
                      onPressed: () => _showPassengers(t),
                      child: const Text('عرض الركاب', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
