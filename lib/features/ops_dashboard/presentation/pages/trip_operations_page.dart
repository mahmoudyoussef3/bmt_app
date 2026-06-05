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
  String status;
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

  double get fillPercentage => maxSeats == 0 ? 0 : passengerCount / maxSeats;
}

class TripOperationsPage extends StatefulWidget {
  final bool showBackButton;

  const TripOperationsPage({this.showBackButton = true, super.key});

  @override
  State<TripOperationsPage> createState() => _TripOperationsPageState();
}

class _TripOperationsPageState extends State<TripOperationsPage> {
  final List<_TripItem> _trips = [
    _TripItem(
      id: 'TR-224',
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      driver: 'محمد أحمد',
      passengerCount: 10,
      maxSeats: 12,
      status: 'قادمة',
      passengers: [
        'عمر فاروق',
        'سارة أحمد',
        'شريف علي',
        'نهى محمود',
        'رنا يوسف',
        'أحمد كمال',
        'خالد يحيى',
        'منى حسن',
        'كريم محمد',
        'هاني صلاح',
      ],
    ),
    _TripItem(
      id: 'TR-221',
      route: 'بنها ← مدينة نصر',
      departureTime: '08:45 ص',
      driver: 'كريم حسن',
      passengerCount: 12,
      maxSeats: 12,
      status: 'جارية',
      passengers: [
        'يوسف شريف',
        'نادين خالد',
        'خالد محمود',
        'ياسمين علي',
        'منى شريف',
        'حسام ناصر',
        'طارق محمد',
        'محمود مصطفى',
        'شادي أيمن',
        'علا سعيد',
        'مروة أحمد',
        'سعد مرسي',
      ],
    ),
    _TripItem(
      id: 'TR-223',
      route: 'بنها ← المهندسين',
      departureTime: '09:00 ص',
      driver: 'مصطفى علي',
      passengerCount: 8,
      maxSeats: 12,
      status: 'قادمة',
      passengers: [
        'أحمد علي',
        'منى حسن',
        'طارق محمد',
        'سامح محمود',
        'خالد كمال',
        'رانيا سعد',
        'سارة حسن',
        'فادي سمير',
      ],
    ),
    _TripItem(
      id: 'TR-220',
      route: 'بنها ← أكتوبر',
      departureTime: '07:30 ص',
      driver: 'أحمد سعيد',
      passengerCount: 12,
      maxSeats: 12,
      status: 'مكتملة',
      passengers: [
        'نادر أحمد',
        'جمال سعيد',
        'أمل مرسي',
        'إبراهيم علي',
        'هالة محمد',
        'سلوى محمود',
        'تامر خالد',
        'عمر مجدي',
        'ماجدة يوسف',
        'وليد حسن',
        'حنان مصطفى',
        'أمير أشرف',
      ],
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

  final List<String> _availableDrivers = [
    'محمد أحمد',
    'كريم حسن',
    'مصطفى علي',
    'أحمد سعيد',
    'سعد مرسي',
    'هاني صلاح',
    'حسين عادل',
    'إيهاب طاهر',
  ];

  final List<String> _statuses = const [
    'الكل',
    'قادمة',
    'جارية',
    'مكتملة',
    'ملغاة',
  ];

  String _selectedStatus = 'الكل';

  int get _totalTripsCount => _trips.length;
  int get _completedTripsCount =>
      _trips.where((trip) => trip.status == 'مكتملة').length;
  int get _activeTripsCount =>
      _trips.where((trip) => trip.status == 'جارية').length;

  List<_TripItem> get _visibleTrips {
    if (_selectedStatus == 'الكل') return _trips;
    return _trips.where((trip) => trip.status == _selectedStatus).toList();
  }

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
        return Colors.cyan.shade300;
      case 'جارية':
        return Colors.orange.shade300;
      case 'مكتملة':
        return Colors.green.shade400;
      case 'ملغاة':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getFillColor(_TripItem trip) {
    if (trip.status == 'ملغاة') return Colors.red.shade300;
    if (trip.fillPercentage >= 1) return Colors.orange.shade300;
    return Colors.green.shade400;
  }

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
                  decoration: const InputDecoration(labelText: 'المسار'),
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
                    trip.route = routeCtrl.text.trim().isEmpty
                        ? trip.route
                        : routeCtrl.text.trim();
                    trip.departureTime = timeCtrl.text.trim().isEmpty
                        ? trip.departureTime
                        : timeCtrl.text.trim();
                  });
                  Navigator.pop(context);
                  _showActionToast('تم تعديل الرحلة ${trip.id}');
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeDriver(_TripItem trip) {
    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تغيير السائق ${trip.id}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _availableDrivers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final driver = _availableDrivers[index];
                  final isCurrent = trip.driver == driver;

                  return ListTile(
                    title: Text(driver),
                    leading: Icon(
                      Icons.person_rounded,
                      color: isCurrent
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_rounded, color: scheme.primary)
                        : null,
                    onTap: () {
                      setState(() => trip.driver = driver);
                      Navigator.pop(context);
                      _showActionToast('تم تغيير السائق إلى $driver');
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

  void _cancelTrip(_TripItem trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إلغاء الرحلة ${trip.id}'),
            content: const Text(
              'سيتم تحويل حالة الرحلة إلى ملغاة وإشعار الركاب.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  setState(() {
                    trip.status = 'ملغاة';
                    trip.passengerCount = 0;
                  });
                  Navigator.pop(context);
                  _showActionToast('تم إلغاء الرحلة ${trip.id}');
                },
                child: const Text('تأكيد الإلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPassengers(_TripItem trip) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusSheet),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ركاب الرحلة ${trip.id}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(
                          label:
                              '${trip.passengerCount} / ${trip.maxSeats} راكب',
                          color: scheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      trip.route,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: AppSpacing.large),
                    Expanded(
                      child: trip.passengers.isEmpty
                          ? Center(
                              child: Text(
                                'لا يوجد ركاب مسجلون في هذه الرحلة',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: trip.passengers.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final passenger = trip.passengers[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: scheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Text(
                                      passenger[0],
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    passenger,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.phone_rounded),
                                    tooltip: 'اتصال',
                                    onPressed: () => _showActionToast(
                                      'الاتصال بـ $passenger',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الرحلات'),
          centerTitle: true,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.xLarge : AppSpacing.medium,
                vertical: AppSpacing.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(context),
                  const SizedBox(height: AppSpacing.large),
                  _buildToolbar(context),
                  const SizedBox(height: AppSpacing.medium),
                  Expanded(
                    child: _visibleTrips.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _visibleTrips.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.medium),
                            itemBuilder: (context, index) {
                              return _TripOperationsCard(
                                trip: _visibleTrips[index],
                                statusColor: _getStatusColor(
                                  _visibleTrips[index].status,
                                ),
                                fillColor: _getFillColor(_visibleTrips[index]),
                                onEdit: () => _editTrip(_visibleTrips[index]),
                                onChangeDriver: () =>
                                    _changeDriver(_visibleTrips[index]),
                                onCancel: _visibleTrips[index].status == 'ملغاة'
                                    ? null
                                    : () => _cancelTrip(_visibleTrips[index]),
                                onShowPassengers: () =>
                                    _showPassengers(_visibleTrips[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'عدد الرحلات اليوم',
              value: _totalTripsCount.toString(),
              color: scheme.primary,
              icon: Icons.route_rounded,
            ),
          ),
          _MetricDivider(color: scheme.outline.withValues(alpha: 0.14)),
          Expanded(
            child: _SummaryMetric(
              label: 'الرحلات المكتملة',
              value: _completedTripsCount.toString(),
              color: Colors.green.shade400,
              icon: Icons.task_alt_rounded,
            ),
          ),
          _MetricDivider(color: scheme.outline.withValues(alpha: 0.14)),
          Expanded(
            child: _SummaryMetric(
              label: 'الرحلات الجارية',
              value: _activeTripsCount.toString(),
              color: Colors.orange.shade300,
              icon: Icons.near_me_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'قائمة الرحلات',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            StatusChip(
              label: '${_visibleTrips.length} رحلة',
              color: scheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((status) {
              final isSelected = status == _selectedStatus;

              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.small,
                ),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(status),
                  showCheckmark: false,
                  avatar: status == 'الكل'
                      ? const Icon(Icons.list_rounded, size: 16)
                      : CircleAvatar(
                          radius: 4,
                          backgroundColor: _getStatusColor(status),
                        ),
                  onSelected: (_) => setState(() => _selectedStatus = status),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        'لا توجد رحلات بهذه الحالة',
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;

  const _MetricDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 54, color: color);
  }
}

class _TripOperationsCard extends StatelessWidget {
  final _TripItem trip;
  final Color statusColor;
  final Color fillColor;
  final VoidCallback onEdit;
  final VoidCallback onChangeDriver;
  final VoidCallback? onCancel;
  final VoidCallback onShowPassengers;

  const _TripOperationsCard({
    required this.trip,
    required this.statusColor,
    required this.fillColor,
    required this.onEdit,
    required this.onChangeDriver,
    required this.onCancel,
    required this.onShowPassengers,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fillLabel = '${(trip.fillPercentage * 100).round()}%';

    return Card(
      margin: EdgeInsets.zero,
      elevation: AppTokens.cardElevation,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.route,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.id,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                StatusChip(label: trip.status, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _InfoPill(
                  icon: Icons.schedule_rounded,
                  label: 'وقت الانطلاق',
                  value: trip.departureTime,
                ),
                _InfoPill(
                  icon: Icons.badge_rounded,
                  label: 'السائق',
                  value: trip.driver,
                ),
                _InfoPill(
                  icon: Icons.groups_rounded,
                  label: 'عدد الركاب',
                  value: '${trip.passengerCount} / ${trip.maxSeats}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Text(
                  'نسبة الامتلاء',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: trip.fillPercentage.clamp(0, 1),
                      minHeight: 7,
                      color: fillColor,
                      backgroundColor: fillColor.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  fillLabel,
                  style: TextStyle(
                    color: fillColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _ActionButton(
                  label: 'تعديل الرحلة',
                  icon: Icons.edit_rounded,
                  onPressed: onEdit,
                ),
                _ActionButton(
                  label: 'تغيير السائق',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: onChangeDriver,
                ),
                _ActionButton(
                  label: 'إلغاء الرحلة',
                  icon: Icons.cancel_outlined,
                  onPressed: onCancel,
                  isDestructive: true,
                ),
                _ActionButton(
                  label: 'عرض الركاب',
                  icon: Icons.people_alt_rounded,
                  onPressed: onShowPassengers,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: color,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.32),
        side: BorderSide(
          color: onPressed == null
              ? scheme.outline.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.42),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
    );
  }
}
