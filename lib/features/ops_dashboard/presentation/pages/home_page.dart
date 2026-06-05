import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import '../cubit/kpi_cubit.dart';
import 'booking_management_page.dart';
import 'trip_operations_page.dart';

// Private helper models for the clean mock datasets
class _KpiMock {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiMock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _QuickActionMock {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionMock({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _AlertMock {
  final String title;
  final String detail;
  final String priority; // عاجل, متوسط, منخفض
  const _AlertMock({
    required this.title,
    required this.detail,
    required this.priority,
  });
}

class _TripMock {
  final String route;
  final String departureTime;
  final String driver;
  final double fillPercentage; // e.g. 0.85
  const _TripMock({
    required this.route,
    required this.departureTime,
    required this.driver,
    required this.fillPercentage,
  });
}

class OpsHomePage extends StatefulWidget {
  const OpsHomePage({super.key});

  @override
  State<OpsHomePage> createState() => _OpsHomePageState();
}

class _OpsHomePageState extends State<OpsHomePage> {
  // Simplified mock datasets
  final List<_KpiMock> _kpisList = const [
    _KpiMock(
      label: 'الرحلات اليوم',
      value: '٢٤ رحلة',
      icon: Icons.directions_bus_rounded,
      color: Colors.green,
    ),
    _KpiMock(
      label: 'الحجوزات الجديدة',
      value: '١٥٦ حجز',
      icon: Icons.bookmark_add_rounded,
      color: Colors.green,
    ),
    _KpiMock(
      label: 'الشكاوى المفتوحة',
      value: '٣ شكاوى',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
    ),
    _KpiMock(
      label: 'المدفوعات المعلقة',
      value: '٥ مدفوعات',
      icon: Icons.pending_actions_rounded,
      color: Colors.orange,
    ),
  ];

  final List<_AlertMock> _alerts = const [
    _AlertMock(
      title: 'رحلة متأخرة TR-224',
      detail: 'متأخرة عن موعد الانطلاق بـ ١٥ دقيقة',
      priority: 'عاجل',
    ),
    _AlertMock(
      title: 'دفعة تحتاج مراجعة',
      detail: 'تحويل بقيمة ٢٥٠ ج.م من العميل عمر فاروق',
      priority: 'متوسط',
    ),
    _AlertMock(
      title: 'شكوى جديدة قيد الانتظار',
      detail: 'العميل يوسف شريف يبلغ عن مشكلة تقنية بالدفع',
      priority: 'منخفض',
    ),
  ];

  final List<_TripMock> _upcomingTrips = const [
    _TripMock(
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      driver: 'محمد أحمد',
      fillPercentage: 0.83, // 10/12
    ),
    _TripMock(
      route: 'بنها ← مدينة نصر',
      departureTime: '08:45 ص',
      driver: 'كريم حسن',
      fillPercentage: 1.0, // 12/12
    ),
    _TripMock(
      route: 'بنها ← المهندسين',
      departureTime: '09:00 ص',
      driver: 'مصطفى علي',
      fillPercentage: 0.66, // 8/12
    ),
    _TripMock(
      route: 'بنها ← أكتوبر',
      departureTime: '09:15 ص',
      driver: 'أحمد سعيد',
      fillPercentage: 0.41, // 5/12
    ),
    _TripMock(
      route: 'بنها ← التجمع الخامس',
      departureTime: '09:30 ص',
      driver: 'سعد مرسي',
      fillPercentage: 0.75, // 9/12
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<KpiCubit>();
    Future.microtask(() => cubit.loadKpis());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<_QuickActionMock> _getQuickActions() {
    return [
      _QuickActionMock(
        label: 'إنشاء رحلة',
        icon: Icons.add_road_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TripOperationsPage()),
        ),
      ),
      _QuickActionMock(
        label: 'إنشاء حجز',
        icon: Icons.add_shopping_cart_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookingManagementPage()),
        ),
      ),
      _QuickActionMock(
        label: 'إضافة عميل',
        icon: Icons.person_add_rounded,
        onTap: () => _showActionToast('إضافة عميل جديد'),
      ),
      _QuickActionMock(
        label: 'إضافة سائق',
        icon: Icons.local_shipping_rounded,
        onTap: () => _showActionToast('إضافة سائق جديد'),
      ),
      _QuickActionMock(
        label: 'فتح الشكاوى',
        icon: Icons.rate_review_rounded,
        onTap: () => _showActionToast('فتح قائمة الشكاوى'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: HEADER
                  _buildHeader(context, scheme, w),
                  const SizedBox(height: AppSpacing.large),

                  // RESPONSIVE SPLIT LAYOUT
                  _buildResponsiveDashboardLayout(w, scheme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Section 1: Header
  Widget _buildHeader(BuildContext context, ColorScheme scheme, double width) {
    final bool isCompact = width < 720;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Flex(
        direction: isCompact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: isCompact ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          // Greeting & Active Staff Info
          Expanded(
            flex: isCompact ? 0 : 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً أحمد 👋',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Row(
                  children: [
                    Text(
                      'الجمعة ٥ يونيو ٢٠٢٦',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.55),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '١٥ موظف نشط حالياً',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompact) const SizedBox(height: AppSpacing.medium),
          // Actions: Quick Search & Notifications
          Expanded(
            flex: isCompact ? 0 : 3,
            child: Row(
              children: [
                // Quick Search Bar
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                      border: Border.all(color: scheme.outline.withOpacity(0.12)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'بحث سريع...',
                        hintStyle: TextStyle(
                          color: scheme.onSurface.withOpacity(0.4),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurface.withOpacity(0.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (val) => _showActionToast('البحث عن: $val'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                // Notifications button
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: scheme.onSurface,
                        size: 26,
                      ),
                      onPressed: () => _showActionToast('تم فتح التنبيهات'),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: scheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 1.5),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Responsive Layout Dispatcher
  Widget _buildResponsiveDashboardLayout(double width, ColorScheme scheme) {
    if (width >= 1100) {
      // Desktop Layout: Main feed on the right (flex 5), alerts/actions on the left sidebar (flex 2)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Column
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiOverview(width, scheme),
                const SizedBox(height: AppSpacing.large),
                _buildQuickActions(width, scheme),
                const SizedBox(height: AppSpacing.large),
                _buildUpcomingTrips(scheme),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.large),
          // Sidebar Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlertsSection(scheme),
              ],
            ),
          )
        ],
      );
    } else {
      // Mobile / Tablet stacked column layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiOverview(width, scheme),
          const SizedBox(height: AppSpacing.large),
          _buildQuickActions(width, scheme),
          const SizedBox(height: AppSpacing.large),
          _buildAlertsSection(scheme),
          const SizedBox(height: AppSpacing.large),
          _buildUpcomingTrips(scheme),
        ],
      );
    }
  }

  // Section 2: Daily Operations Overview
  Widget _buildKpiOverview(double width, ColorScheme scheme) {
    int crossAxisCount = 4;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    }

    final double childAspectRatio = width < 600 ? 3.8 : 2.5;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kpisList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, i) {
        final k = _kpisList[i];
        return Card(
          elevation: AppTokens.surfaceElevation,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: k.color, width: 4.5),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: k.color.withOpacity(0.12),
                  child: Icon(k.icon, color: k.color, size: 22),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        k.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        k.value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Section 3: Quick Actions
  Widget _buildQuickActions(double width, ColorScheme scheme) {
    final actions = _getQuickActions();
    int crossAxisCount = 5;
    if (width < 600) {
      crossAxisCount = 2;
    } else if (width < 960) {
      crossAxisCount = 3;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإجراءات السريعة',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.medium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: width < 600 ? 2.2 : 1.35,
            ),
            itemBuilder: (context, i) {
              final act = actions[i];
              return InkWell(
                onTap: act.onTap,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    border: Border.all(color: scheme.outline.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.medium),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(act.icon, color: scheme.primary, size: 24),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        act.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // Section 4: Today's Alerts
  Widget _buildAlertsSection(ColorScheme scheme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تنبيهات اليوم',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.medium),
          ..._alerts.map((a) => _buildAlertItem(a, scheme)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(_AlertMock a, ColorScheme scheme) {
    Color priorityColor;
    String priorityText;
    Color bgTint;

    switch (a.priority) {
      case 'عاجل':
        priorityColor = Colors.red.shade400;
        priorityText = 'عاجل';
        bgTint = Colors.red.shade900.withOpacity(0.12);
        break;
      case 'متوسط':
        priorityColor = Colors.orange.shade400;
        priorityText = 'متوسط';
        bgTint = Colors.orange.shade900.withOpacity(0.1);
        break;
      case 'منخفض':
      default:
        priorityColor = Colors.blue.shade400;
        priorityText = 'منخفض';
        bgTint = Colors.blue.shade900.withOpacity(0.1);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border(
          right: BorderSide(color: priorityColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                a.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: priorityColor,
                ),
              ),
              StatusChip(
                label: priorityText,
                color: priorityColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            a.detail,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.75),
            ),
          )
        ],
      ),
    );
  }

  // Section 5: Upcoming Trips
  Widget _buildUpcomingTrips(ColorScheme scheme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرحلات القادمة (الـ 5 القادمة)',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.medium),
          ..._upcomingTrips.map((t) => _buildTripCard(t, scheme)),
        ],
      ),
    );
  }

  Widget _buildTripCard(_TripMock t, ColorScheme scheme) {
    final bool isFull = t.fillPercentage >= 1.0;
    final Color progressColor = isFull ? Colors.red.shade400 : Colors.green.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.route,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              Text(
                t.departureTime,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: scheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                'السائق: ${t.driver}',
                style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7)),
              ),
              const Spacer(),
              Text(
                'نسبة الامتلاء: ${(t.fillPercentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: t.fillPercentage,
              minHeight: 5,
              color: progressColor,
              backgroundColor: progressColor.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
              ),
              onPressed: () => _showActionToast('تفاصيل رحلة: ${t.route}'),
              child: const Text('عرض التفاصيل', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
