import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';

class _CustomerItem {
  final String id;
  final String name;
  final String phone;
  final int tripCount;
  final String currentSubscription;
  final String walletBalance;
  final String lastTrip;
  final String upcomingTrip;
  final int bookingCount;
  final int complaintCount;
  final String note;

  const _CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.tripCount,
    required this.currentSubscription,
    required this.walletBalance,
    required this.lastTrip,
    required this.upcomingTrip,
    required this.bookingCount,
    required this.complaintCount,
    required this.note,
  });
}

String _arabicDigits(Object value) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var text = value.toString();
  for (var i = 0; i < western.length; i++) {
    text = text.replaceAll(western[i], arabic[i]);
  }
  return text;
}

String _customerDisplayId(_CustomerItem customer) {
  final digits = customer.id.replaceAll(RegExp('[^0-9]'), '');
  return 'عميل ${_arabicDigits(digits)}';
}

class CustomerManagementPage extends StatefulWidget {
  final bool showBackButton;

  const CustomerManagementPage({this.showBackButton = true, super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _CustomerItem? _selectedCustomer;

  final List<_CustomerItem> _customers = const [
    _CustomerItem(
      id: 'C-1024',
      name: 'سارة أحمد',
      phone: '01012345678',
      tripCount: 48,
      currentSubscription: 'شهري نشط',
      walletBalance: '٣٢٠ ج.م',
      lastTrip: 'بنها ← القرية الذكية',
      upcomingTrip: 'اليوم 08:30 ص',
      bookingCount: 3,
      complaintCount: 0,
      note: 'تفضل المقعد الأمامي عند توفره',
    ),
    _CustomerItem(
      id: 'C-1031',
      name: 'خالد محمود',
      phone: '01234567890',
      tripCount: 32,
      currentSubscription: 'أسبوعي نشط',
      walletBalance: '٨٥ ج.م',
      lastTrip: 'بنها ← مدينة نصر',
      upcomingTrip: 'غداً 08:45 ص',
      bookingCount: 2,
      complaintCount: 1,
      note: 'لديه شكوى مفتوحة بخصوص الدفع',
    ),
    _CustomerItem(
      id: 'C-1040',
      name: 'رنا يوسف',
      phone: '01122334455',
      tripCount: 19,
      currentSubscription: 'بدون اشتراك',
      walletBalance: '٠ ج.م',
      lastTrip: 'بنها ← المهندسين',
      upcomingTrip: 'لا يوجد',
      bookingCount: 1,
      complaintCount: 2,
      note: 'تحتاج متابعة قبل إنشاء حجز جديد',
    ),
    _CustomerItem(
      id: 'C-1048',
      name: 'عمر فاروق',
      phone: '01555667788',
      tripCount: 76,
      currentSubscription: 'ربع سنوي نشط',
      walletBalance: '٦٥٠ ج.م',
      lastTrip: 'بنها ← القرية الذكية',
      upcomingTrip: 'اليوم 08:30 ص',
      bookingCount: 4,
      complaintCount: 0,
      note: 'عميل منتظم على نفس المسار',
    ),
    _CustomerItem(
      id: 'C-1053',
      name: 'ياسمين علي',
      phone: '01009876543',
      tripCount: 27,
      currentSubscription: 'شهري ينتهي قريباً',
      walletBalance: '١٤٠ ج.م',
      lastTrip: 'بنها ← التجمع الخامس',
      upcomingTrip: 'غداً 09:30 ص',
      bookingCount: 2,
      complaintCount: 0,
      note: 'مرشحة لتجديد الاشتراك',
    ),
    _CustomerItem(
      id: 'C-1062',
      name: 'طارق محمد',
      phone: '01199887766',
      tripCount: 12,
      currentSubscription: 'أسبوعي متوقف',
      walletBalance: '٢٥ ج.م',
      lastTrip: 'بنها ← المهندسين',
      upcomingTrip: 'الأحد 09:00 ص',
      bookingCount: 1,
      complaintCount: 1,
      note: 'تأكد من حالة الاشتراك قبل الحجز',
    ),
  ];

  List<_CustomerItem> get _filteredCustomers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).toList();
  }

  _CustomerItem get _previewCustomer {
    if (_selectedCustomer != null &&
        _filteredCustomers.contains(_selectedCustomer)) {
      return _selectedCustomer!;
    }
    return _filteredCustomers.isNotEmpty
        ? _filteredCustomers.first
        : _customers.first;
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

  void _runAction(_CustomerItem customer, String action) {
    _showActionToast('$action للعميل ${customer.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة العملاء'),
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
            final isWide = constraints.maxWidth >= 980;
            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _buildLookupPanel(context)),
                      const SizedBox(width: AppSpacing.large),
                      Expanded(
                        flex: 4,
                        child: _CustomerProfilePreview(
                          customer: _previewCustomer,
                          onAction: _runAction,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildLookupPanel(context),
                      const SizedBox(height: AppSpacing.medium),
                      _CustomerProfilePreview(
                        customer: _previewCustomer,
                        onAction: _runAction,
                      ),
                    ],
                  );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.xLarge : AppSpacing.medium,
                vertical: AppSpacing.medium,
              ),
              child: content,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLookupPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(context),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: Text(
                'نتائج البحث',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            StatusChip(
              label: '${_arabicDigits(_filteredCustomers.length)} عميل',
              color: scheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        if (_filteredCustomers.isEmpty)
          _buildEmptyState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredCustomers.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.medium),
            itemBuilder: (context, index) {
              final customer = _filteredCustomers[index];
              final isSelected = customer == _previewCustomer;

              return _CustomerCard(
                customer: customer,
                isSelected: isSelected,
                onSelect: () => setState(() => _selectedCustomer = customer),
                onAction: _runAction,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        keyboardType: TextInputType.text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو الهاتف...',
          hintStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.42),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedCustomer = null;
                    });
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _selectedCustomer = null;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            color: scheme.onSurface.withValues(alpha: 0.42),
            size: 36,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'لا يوجد عميل مطابق',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final _CustomerItem customer;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(_CustomerItem customer, String action) onAction;

  const _CustomerCard({
    required this.customer,
    required this.isSelected,
    required this.onSelect,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: AppTokens.cardElevation,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.65)
              : scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      customer.name[0],
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.62),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: customer.currentSubscription,
                    color: _subscriptionColor(customer.currentSubscription),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _CustomerFact(
                    icon: Icons.route_rounded,
                    label: 'عدد الرحلات',
                    value: _arabicDigits(customer.tripCount),
                  ),
                  _CustomerFact(
                    icon: Icons.workspace_premium_rounded,
                    label: 'الاشتراك الحالي',
                    value: customer.currentSubscription,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _CustomerActionButton(
                    label: 'إنشاء حجز',
                    icon: Icons.add_shopping_cart_rounded,
                    onPressed: () => onAction(customer, 'إنشاء حجز'),
                    isPrimary: true,
                  ),
                  _CustomerActionButton(
                    label: 'عرض الحجوزات',
                    icon: Icons.list_alt_rounded,
                    onPressed: () => onAction(customer, 'عرض الحجوزات'),
                  ),
                  _CustomerActionButton(
                    label: 'الاشتراكات',
                    icon: Icons.card_membership_rounded,
                    onPressed: () => onAction(customer, 'الاشتراكات'),
                  ),
                  _CustomerActionButton(
                    label: 'المحفظة',
                    icon: Icons.account_balance_wallet_rounded,
                    onPressed: () => onAction(customer, 'المحفظة'),
                  ),
                  _CustomerActionButton(
                    label: 'الشكاوى',
                    icon: Icons.support_agent_rounded,
                    onPressed: () => onAction(customer, 'الشكاوى'),
                    isDestructive: customer.complaintCount > 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _subscriptionColor(String subscription) {
    if (subscription.contains('نشط')) return Colors.green.shade400;
    if (subscription.contains('ينتهي')) return Colors.orange.shade300;
    if (subscription.contains('متوقف')) return Colors.red.shade300;
    return Colors.grey.shade400;
  }
}

class _CustomerProfilePreview extends StatelessWidget {
  final _CustomerItem customer;
  final void Function(_CustomerItem customer, String action) onAction;

  const _CustomerProfilePreview({
    required this.customer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  child: Text(
                    'معاينة العميل',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusChip(
                  label: _customerDisplayId(customer),
                  color: scheme.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    customer.name[0],
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            _PreviewRow(
              icon: Icons.route_rounded,
              label: 'عدد الرحلات',
              value: _arabicDigits(customer.tripCount),
            ),
            _PreviewRow(
              icon: Icons.workspace_premium_rounded,
              label: 'الاشتراك الحالي',
              value: customer.currentSubscription,
            ),
            _PreviewRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'رصيد المحفظة',
              value: customer.walletBalance,
            ),
            _PreviewRow(
              icon: Icons.confirmation_number_rounded,
              label: 'الحجوزات النشطة',
              value: _arabicDigits(customer.bookingCount),
            ),
            _PreviewRow(
              icon: Icons.support_agent_rounded,
              label: 'الشكاوى المفتوحة',
              value: _arabicDigits(customer.complaintCount),
            ),
            _PreviewRow(
              icon: Icons.history_rounded,
              label: 'آخر رحلة',
              value: customer.lastTrip,
            ),
            _PreviewRow(
              icon: Icons.event_rounded,
              label: 'الرحلة القادمة',
              value: customer.upcomingTrip,
            ),
            const SizedBox(height: AppSpacing.medium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                customer.note,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(customer, 'إنشاء حجز'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إنشاء حجز'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                IconButton.filledTonal(
                  onPressed: () => onAction(customer, 'اتصال'),
                  icon: const Icon(Icons.phone_rounded),
                  tooltip: 'اتصال',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CustomerFact({
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.56),
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

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CustomerActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _CustomerActionButton({
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
        side: BorderSide(color: color.withValues(alpha: 0.38)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
    );
  }
}
